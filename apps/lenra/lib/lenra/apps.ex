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

  alias Lenra.Repo

  alias Lenra.{Accounts, EmailWorker, GitlabApiServices, OpenfaasServices}

  alias Lenra.Apps.{
    App,
    Build,
    Deployment,
    Environment,
    MainEnv,
    UserEnvironmentAccess
  }

  alias ApplicationRunner.MongoStorage.MongoUserLink

  alias Lenra.Errors.{BusinessError, TechnicalError}

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

  @doc """
    The `all_apps_user_opened` method takes a `user_id` and returns a list of Applications that the user has opened at least one.
    This means that the user has an account on these applications and that the `MongoUserLink` relation has already been created.
  """
  def all_apps_user_opened(user_id) do
    Repo.all(
      from(a in App,
        left_join: e in Environment,
        on: a.id == e.application_id,
        left_join: m in MongoUserLink,
        on: e.id == m.environment_id,
        where: m.user_id == ^user_id
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
      |> update_build_after_pipeline()
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

  defp update_build_after_pipeline(multi) do
    multi
    |> Ecto.Multi.update(:update_build_after_pipeline, fn
      %{inserted_build: %Build{} = build, gitlab_pipeline: pipeline} ->
        pipeline = Jason.decode!(pipeline)
        Build.changeset(build, %{"pipeline_id" => pipeline["id"]})
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

  #########################
  # USerEnvironmentAccess #
  #########################

  def all_user_env_access(env_id) do
    Repo.all(
      from(e in UserEnvironmentAccess,
        where: e.environment_id == ^env_id,
        select: %{environment_id: e.environment_id, email: e.email}
      )
    )
  end

  def fetch_user_env_access(clauses, error \\ TechnicalError.error_404_tuple()) do
    Repo.fetch_by(UserEnvironmentAccess, clauses, error)
  end

  def accept_invitation(id, %Accounts.User{} = user) do
    with %UserEnvironmentAccess{} = access <- Repo.get(UserEnvironmentAccess, id),
         true <- access.email == user.email do
      access
      |> UserEnvironmentAccess.changeset(%{user_id: user.id})
      |> Repo.update()

      service_name =
        Repo.one(
          from(a in App,
            join: e in Environment,
            on: e.application_id == a.id,
            where: e.id == ^access.environment_id,
            select: a.service_name
          )
        )

      {:ok, %{app_name: service_name}}
    else
      false -> BusinessError.invitation_wrong_email(:wrong_email)
      err -> err
    end
  end

  def create_user_env_access(env_id, %{"email" => email}) do
    Accounts.User
    |> Lenra.Repo.get_by(email: email)
    |> handle_create_user_env_access(env_id, email)
    |> Ecto.Multi.run(:add_invitation_events, fn repo, %{inserted_user_access: inserted_user_access} ->
      %{application: app} =
        env_id
        |> get_env()
        |> repo.preload(:application)

      add_invitation_events(app, inserted_user_access, email)
    end)
    |> Repo.transaction()
  end

  defp handle_create_user_env_access(nil, env_id, email) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :inserted_user_access,
      UserEnvironmentAccess.changeset(%UserEnvironmentAccess{}, %{
        email: email,
        environment_id: env_id
      })
    )
  end

  defp handle_create_user_env_access(%Accounts.User{} = user, env_id, email) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :inserted_user_access,
      UserEnvironmentAccess.changeset(%UserEnvironmentAccess{}, %{
        user_id: user.id,
        email: email,
        environment_id: env_id
      })
    )
  end

  defp add_invitation_events(app, user_access, email) do
    lenra_app_url = Application.fetch_env!(:lenra, :lenra_app_url)
    invitation_link = "#{lenra_app_url}/#/app/invitations/#{user_access.id}"

    EmailWorker.add_email_invitation_event(email, app.name, invitation_link)
  end

  def delete_user_env_access(%{environment_id: env_id, user_id: user_id} = _params) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:user_access, fn _repo, _changes ->
      fetch_user_env_access(environment_id: env_id, user_id: user_id)
    end)
    |> Ecto.Multi.delete(:deleted_user_access, fn %{user_access: user_access} -> user_access end)
  end
end
