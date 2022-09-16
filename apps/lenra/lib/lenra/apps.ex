defmodule Lenra.Apps do
  @moduledoc """
    This Lenra.Apps context is responsible for the management of the developper apps.
    An app can have any number of Builds.
    An app can have one or more Environments
    A Deployment is an association between a build and an Environment
    The "MainEnv" is an association between an App and an Environment.
    This associated Environment is used by default to deploy a build.
    An app can only have one "MainEnv"

    When we create a new build with create_build_and_trigger_pipeline/3 :
    First a new build is inserted in the database.
    Then, the Gitlab pipeline is triggered to create the docker image associated with the build.
    When the pipeline end (success or failure) we can update the build to change the status.
    And a new deployment is triggered in the MainEnv :
     - We create the deployment in the database
     - We trigger the HTTP call to deploy the docker image in Openfaas

  """
  import Ecto.Query

  alias ApplicationRunner.JsonStorage.Datastore
  alias Lenra.Repo

  alias Lenra.{GitlabApiServices, OpenfaasServices, UserEnvironmentAccess}

  alias Lenra.Apps.{
    App,
    Build,
    Deployment,
    Environment,
    MainEnv
  }

  #######
  # App #
  #######

  def all_apps(user_id) do
    Repo.all(
      from(a in App,
        join: m in MainEnv,
        on: a.id == m.application_id,
        join: e in Environment,
        on: m.environment_id == e.id,
        left_join: u in UserEnvironmentAccess,
        on: e.id == u.environment_id and ^user_id == u.user_id,
        where: a.creator_id == ^user_id or e.is_public or u.user_id == ^user_id
      )
    )
  end

  def all_apps_for_user(user_id) do
    Repo.all(
      from(a in App,
        where: a.creator_id == ^user_id,
        select: %{
          id: a.id,
          name: a.name,
          color: a.color,
          icon: a.icon,
          service_name: a.service_name,
          creator_id: a.creator_id,
          repository: a.repository,
          repository_branch: a.repository_branch
        }
      )
    )
  end

  def fetch_app(app_id) do
    Repo.fetch(App, app_id)
  end

  def fetch_app_by(clauses) do
    Repo.fetch_by(App, clauses)
  end

  def create_app(user_id, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:inserted_application, App.new(user_id, params))
    |> create_env_multi(user_id, %{name: "live", is_ephemeral: false, is_public: false})
    |> Ecto.Multi.insert(:application_main_env, fn %{
                                                     inserted_application: app,
                                                     inserted_env: env
                                                   } ->
      MainEnv.new(app.id, env.id)
    end)
    |> Repo.transaction()
  end

  def update_app(app, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:updated_application, App.update(app, params))
    |> Repo.transaction()
  end

  def delete_app(app) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:deleted_application, app)
    |> Repo.transaction()
  end

  ###############
  # Environment #
  ###############

  def all_envs_for_app(app_id) do
    Repo.all(from(e in Environment, where: e.application_id == ^app_id))
  end

  def get_env(env_id) do
    Repo.get(Environment, env_id)
  end

  def fetch_env(env_id) do
    Repo.fetch(Environment, env_id)
  end

  def create_env(application_id, creator_id, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.put(:inserted_application, %{id: application_id})
    |> create_env_multi(creator_id, params)
    |> Repo.transaction()
  end

  defp create_env_multi(multi, creator_id, params) do
    multi
    |> Ecto.Multi.insert(:inserted_env, fn %{inserted_application: app} ->
      Environment.new(app.id, creator_id, nil, params)
    end)
  end

  def update_env(env, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:updated_env, Environment.update(env, params))
    |> Repo.transaction()
  end

  ############
  # Main Env #
  ############

  def fetch_main_env_for_app(app_id) do
    main_env = Repo.get_by(MainEnv, application_id: app_id)
    Repo.fetch_by(Environment, id: main_env.environment_id)
  end

  ##########
  # Builds #
  ##########

  def all_builds(app_id) do
    Repo.all(from(b in Build, where: b.application_id == ^app_id))
  end

  def fetch_build(build_id) do
    Repo.fetch(Build, build_id)
  end

  def create_build_and_trigger_pipeline(creator_id, app_id, params) do
    with {:ok, %App{} = app} <- fetch_app(app_id) do
      creator_id
      |> create_build(app.id, params)
      |> Ecto.Multi.run(:gitlab_pipeline, fn _repo, %{inserted_build: %Build{} = build} ->
        GitlabApiServices.create_pipeline(
          app.service_name,
          app.repository,
          app.repository_branch,
          build.id,
          build.build_number
        )
      end)
      |> Repo.transaction()
    end
  end

  defp create_build(creator_id, app_id, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:build_number, fn repo, _result ->
      {:ok,
       repo.one(
         from(b in Build,
           select: (b.build_number |> max() |> coalesce(0)) + 1,
           where: b.application_id == ^app_id
         )
       )}
    end)
    |> Ecto.Multi.insert(:inserted_build, fn %{build_number: build_number} ->
      Build.new(creator_id, app_id, build_number, params)
    end)
  end

  def update_build(build, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:updated_build, Build.update(build, params))
    |> Repo.transaction()
  end

  ###############
  # Deployments #
  ###############

  def deploy_in_main_env(%Build{} = build) do
    with loaded_build <- Repo.preload(build, :application),
         loaded_app <- Repo.preload(loaded_build.application, :main_env) do
      create_deployment(loaded_app.main_env.environment_id, build.id, build.creator_id)
    end
  end

  def create_deployment(environment_id, build_id, publisher_id, params \\ %{}) do
    build =
      Build
      |> Repo.get(build_id)
      |> Repo.preload(:application)

    env = get_env(environment_id)

    # TODO: back previous deployed build, check if it's present in another env and if not, remove it from OpenFaaS

    Ecto.Multi.new()
    |> Ecto.Multi.update(:updated_env, Ecto.Changeset.change(env, deployed_build_id: build.id))
    |> Ecto.Multi.insert(
      :inserted_deployment,
      Deployment.new(build.application.id, environment_id, build_id, publisher_id, params)
    )
    |> Ecto.Multi.run(:openfaas_deploy, fn _repo, _result ->
      # TODO: check if this build is already deployed on another env
      OpenfaasServices.deploy_app(
        build.application.service_name,
        build.build_number
      )
    end)
    |> Repo.transaction()
  end

  def image_name(service_name, build_number) do
    lenra_env = Application.fetch_env!(:lenra, :lenra_env)
    faas_registry = Application.fetch_env!(:lenra, :faas_registry)

    "#{faas_registry}/#{lenra_env}/#{service_name}:#{build_number}"
  end
end
