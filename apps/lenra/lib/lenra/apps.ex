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

  alias Lenra.Kubernetes.StatusDynSup
  alias Lenra.Repo
  alias Lenra.Subscriptions

  alias Lenra.{Accounts, EmailWorker, GitlabApiServices, OpenfaasServices}

  alias Lenra.Kubernetes.ApiServices

  alias Lenra.Apps.{
    App,
    Build,
    Deployment,
    Environment,
    MainEnv,
    OAuth2Client,
    UserEnvironmentAccess
  }

  alias ApplicationRunner.MongoStorage.MongoUserLink

  alias Lenra.Errors.{BusinessError, TechnicalError}

  require Logger

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

  def fetch_app_for_env(env_id) do
    Environment
    |> Repo.get(env_id)
    |> Repo.preload(:application)
    |> Map.get(:application)
    |> case do
      nil -> BusinessError.no_env_found_tuple()
      app -> {:ok, app}
    end
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
    Logger.debug("#{__MODULE__} all builds for app id #{app_id}")
    Repo.all(from(b in Build, where: b.application_id == ^app_id, order_by: b.build_number))
  end

  def fetch_build(build_id) do
    Logger.debug("#{__MODULE__} fetch builds for build id #{build_id}")

    Repo.fetch(Build, build_id)
  end

  def create_build_and_deploy(creator_id, app_id, params) do
    Logger.debug(
      "#{__MODULE__} create_build_and_deploy with params #{inspect(%{creator_id: creator_id, app_id: app_id, params: params})}"
    )

    with {:ok, %App{} = app} <- fetch_app(app_id),
         preloaded_app <- Repo.preload(app, :main_env),
         {:ok, %{inserted_build: %Build{} = build}} <-
           creator_id
           |> create_build(app.id, params)
           |> Repo.transaction() do
      case create_deployment(
             preloaded_app.main_env.environment_id,
             build.id,
             creator_id,
             params
           ) do
        {:error, reason} ->
          Logger.critical("Error when inserting deployment in DB. \n\t\t reason : #{inspect(reason)}")

          TechnicalError.unknown_error_tuple(reason)

        _res ->
          Logger.debug("#{__MODULE__} create_build_and_deploy exit successfully")

          trigger_pipeline(build, app_id, params)

          {:ok, %{inserted_build: build}}
      end
    end
  end

  def trigger_pipeline(build, app_id, params) do
    Logger.debug(
      "#{__MODULE__} create_build_and_trigger_pipeline with params #{inspect(%{build: build, app_id: app_id, params: params})}"
    )

    res =
      with {:ok, %App{} = app} <- fetch_app(app_id) do
        {:ok, %{"id" => pipeline_id}} =
          case String.downcase(Application.fetch_env!(:lenra, :pipeline_runner)) do
            "gitlab" ->
              GitlabApiServices.create_pipeline(
                app.service_name,
                app.repository,
                app.repository_branch,
                build.id,
                build.build_number
              )

            "kubernetes" ->
              ApiServices.create_pipeline(
                app.service_name,
                app.repository,
                app.repository_branch,
                build.id,
                build.build_number
              )

            _anything ->
              BusinessError.pipeline_runner_unkown_service_tuple()
          end

        Build.changeset(build, %{"pipeline_id" => pipeline_id}) |> Repo.update()
      end

    Logger.debug("#{__MODULE__} create_build_and_trigger_pipeline exit with res #{inspect(res)}")

    res
  end

  defp create_build(creator_id, app_id, params) do
    Logger.debug(
      "#{__MODULE__} create_build with params #{inspect(%{creator_id: creator_id, app_id: app_id, params: params})}"
    )

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

  def all_deployements(app_id) do
    Repo.all(from(d in Deployment, where: d.application_id == ^app_id, order_by: d.id))
  end

  def get_deployement(build_id, env_id) do
    Repo.one(from(d in Deployment, where: d.build_id == ^build_id and d.environment_id == ^env_id))
  end

  def get_deployement_for_build(build_id) do
    Repo.one(from(d in Deployment, where: d.build_id == ^build_id))
  end

  def deploy_in_main_env(%Build{} = build) do
    with loaded_build <- Repo.preload(build, :application),
         loaded_app <- Repo.preload(loaded_build.application, main_env: [:environment]),
         %Deployment{} = deployment <-
           get_deployement(build.id, loaded_app.main_env.environment.id),
         {:ok, _status} <-
           OpenfaasServices.deploy_app(
             loaded_build.application.service_name,
             build.build_number,
             Subscriptions.get_max_replicas(loaded_build.application.id)
           ) do
      update_deployement(deployment, status: :waitingForAppReady)

      spawn(fn ->
        update_deployement_after_deploy(
          deployment,
          loaded_app.main_env.environment,
          loaded_app.service_name,
          build.build_number
        )
      end)

      {:ok, build}
    end
  end

  def create_deployment(environment_id, build_id, publisher_id, params \\ %{}) do
    Logger.debug(
      "#{__MODULE__} create_deployment with params #{inspect(%{environment_id: environment_id, build_id: build_id, publisher_id: publisher_id, params: params})}"
    )

    build =
      Build
      |> Repo.get(build_id)
      |> Repo.preload(:application)

    # TODO: back previous deployed build, check if it's present in another env and if not, remove it from OpenFaaS

    # TODO: remove useless multi
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :inserted_deployment,
      Deployment.new(build.application.id, environment_id, build_id, publisher_id, params)
    )
    |> Repo.transaction()
  end

  def update_deployement_after_deploy(deployment, env, service_name, build_number),
    do: update_deployement_after_deploy(deployment, env, service_name, build_number, 0)

  def update_deployement_after_deploy(deployment, env, service_name, build_number, retry)
      when retry <= 120 do
    case OpenfaasServices.is_deploy(service_name, build_number) do
      true ->
        transaction =
          Ecto.Multi.new()
          |> Ecto.Multi.update(
            :updated_deployment,
            Ecto.Changeset.change(deployment, status: :success)
          )
          |> Ecto.Multi.run(:updated_env, fn _repo, %{updated_deployment: updated_deployment} ->
            env
            |> Ecto.Changeset.change(deployment_id: updated_deployment.id)
            |> Repo.update()
          end)
          |> Repo.transaction()

        ApplicationServices.stop_app('#{OpenfaasServices.get_function_name(service_name, build_number)}')
        transaction

      # Function not found in openfaas, 2 retry (10s),
      # To let openfaas deploy in case of overload, after 2 retry -> failure
      :error404 ->
        if retry == 3 do
          Logger.critical("Function #{service_name} not deploy on openfaas, this should not appens")

          update_deployement(deployment, status: :failure)
        else
          Process.sleep(5000)
          update_deployement_after_deploy(deployment, env, service_name, build_number, retry + 1)
        end

        :error500

      _any ->
        Process.sleep(5000)
        update_deployement_after_deploy(deployment, env, service_name, build_number, retry + 1)
    end
  end

  def update_deployement_after_deploy(deployment, _env, _service_name, _build_number, _retry),
    do: update_deployement(deployment, status: :failure)

  def update_deployement(deployement, change) do
    deployement
    |> Ecto.Changeset.change(change)
    |> Repo.update()
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

  def create_user_env_access(env_id, %{"email" => email}, subscription) do
    if subscription == nil do
      nb_user_env_access = Repo.all(from(u in UserEnvironmentAccess, where: u.environment_id == ^env_id))

      if length(nb_user_env_access) >= 3 do
        BusinessError.subscription_required_tuple()
      else
        create_user_env_access_transaction(env_id, email)
      end
    else
      create_user_env_access_transaction(env_id, email)
    end
  end

  defp create_user_env_access_transaction(env_id, email) do
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
    invitation_link = "#{lenra_app_url}/app/invitations/#{user_access.id}"

    EmailWorker.add_email_invitation_event(email, app.name, invitation_link)
  end

  def delete_user_env_access(%{environment_id: env_id, user_id: user_id} = _params) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:user_access, fn _repo, _changes ->
      fetch_user_env_access(environment_id: env_id, user_id: user_id)
    end)
    |> Ecto.Multi.delete(:deleted_user_access, fn %{user_access: user_access} -> user_access end)
  end

  def create_oauth2_client(params) do
    with %Ecto.Changeset{valid?: true} = changeset <- OAuth2Client.new(params),
         {:ok, oauth2_client} <- Ecto.Changeset.apply_action(changeset, :create),
         {:ok, %ORY.Hydra.Response{body: %{"client_id" => client_id}} = response} <-
           HydraApi.create_oauth2_client(oauth2_client),
         %Ecto.Changeset{valid?: true} = db_changeset <-
           OAuth2Client.update_for_db(oauth2_client, client_id),
         {:insert, {:ok, inserted}, _client_id} <- {:insert, Repo.insert(db_changeset), client_id} do
      result = %{
        client: inserted,
        secret: %{
          value: response.body["client_secret"],
          expiration: response.body["client_secret_expires_at"]
        }
      }

      {:ok, result}
    else
      {:insert, {:error, _changeset}, client_id} ->
        # Failed during database insertion, delete the oauth client on hydra
        HydraApi.delete_hydra_client(client_id)
        TechnicalError.cannot_save_oauth2_client_tuple()

      %Ecto.Changeset{valid?: false} = changeset ->
        {:error, changeset}

      {:error, reason} ->
        TechnicalError.hydra_request_failed_tuple(reason)
    end
  end

  def update_oauth2_client(%{"client_id" => client_id} = params) do
    with {:ok, hydra_client} <- detailed_oauth2_client_info(client_id),
         oauth2_client_changeset <- hydra_client_to_oauth2_client(hydra_client),
         updated_changeset <- OAuth2Client.update(oauth2_client_changeset, params),
         {:ok, new_oauth2_client} <- Ecto.Changeset.apply_action(updated_changeset, :create),
         {:ok, _result} <- HydraApi.update_oauth2_client(new_oauth2_client) do
      {:ok, new_oauth2_client}
    end
  end

  defp hydra_client_to_oauth2_client(hydra_client) do
    %OAuth2Client{
      name: hydra_client["client_name"],
      scopes: hydra_client["scope"] |> String.split(),
      allowed_origins: hydra_client["allowed_cors_origins"],
      redirect_uris: hydra_client["redirect_uris"],
      environment_id: hydra_client["metadata"]["environment_id"],
      oauth2_client_id: hydra_client["client_id"]
    }
  end

  def delete_oauth2_client(%{"environment_id" => env_id, "client_id" => client_id}) do
    to_delete = Repo.get_by(OAuth2Client, environment_id: env_id, oauth2_client_id: client_id)

    do_delete_oauth2_client(to_delete)
  end

  defp do_delete_oauth2_client(nil) do
    TechnicalError.error_404_tuple()
  end

  defp do_delete_oauth2_client(to_delete) do
    with {:ok, _response} <- HydraApi.delete_hydra_client(to_delete.oauth2_client_id) do
      Repo.delete(to_delete)
    end
  end

  def detailed_oauth2_client_info(oauth2_client_id) do
    case HydraApi.get_hydra_client(oauth2_client_id) do
      {:ok, response} ->
        {:ok, response.body}

      {:error, reason} ->
        TechnicalError.hydra_request_failed_tuple(reason)
    end
  end

  def get_oauth2_clients(env_id) do
    query = from(c in OAuth2Client, where: c.environment_id == ^env_id)

    query
    |> Repo.all()
    |> Enum.map(fn oauth2_client ->
      Task.async(Lenra.Apps, :detailed_oauth2_client_info, [oauth2_client.oauth2_client_id])
    end)
    |> Task.await_many()
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, client_infos}, {:ok, clients} ->
        formatted_client_infos = hydra_client_to_oauth2_client(client_infos)
        {:cont, {:ok, [formatted_client_infos | clients]}}

      error_tuple, _acc ->
        {:halt, error_tuple}
    end)
  end
end
