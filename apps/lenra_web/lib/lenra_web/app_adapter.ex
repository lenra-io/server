defmodule LenraWeb.AppAdapter do
  @moduledoc """
    This adapter give ApplicationRunner the few function that he needs to work correctly.
  """
  @behaviour ApplicationRunner.Adapter

  alias Lenra.Accounts
  alias Lenra.Accounts.User
  alias Lenra.{Apps, Repo}
  alias Lenra.Apps.{App, Environment, MainEnv}
  alias Lenra.Errors.BusinessError

  @impl ApplicationRunner.Adapter
  def allow(user_id, app_name) do
    with %App{} = app <- get_app(app_name),
         %App{} = application <- Repo.preload(app, main_env: [:environment]),
         %User{} = user <- Accounts.get_user(user_id) do
      Bouncer.allow(LenraWeb.AppAdapter.Policy, :join_app, user, application)
    else
      _err ->
        BusinessError.forbidden_tuple()
    end
  end

  @impl ApplicationRunner.Adapter
  def get_function_name(app_name) do
    lenra_env = Application.fetch_env!(:lenra, :lenra_env)

    with %App{} = app <- get_app(app_name),
         %App{} = application <-
           Repo.preload(app, main_env: [environment: [deployment: [:build]]]) do
      build = application.main_env.environment.deployment.build

      if build do
        String.downcase("#{lenra_env}-#{app_name}-#{build.build_number}")
      else
        BusinessError.application_not_built_tuple()
      end
    end
  end

  @impl ApplicationRunner.Adapter
  def get_env_id(app_name) do
    application =
      App
      |> Repo.get_by(service_name: app_name)
      |> Repo.preload(:environments)

    List.first(application.environments).id
  end

  @impl ApplicationRunner.Adapter
  def resource_from_params(params) do
    case LenraWeb.Auth.check_token_and_get_resource(params["token"]) do
      {:ok, user} ->
        {:ok, user.id}

      error ->
        error
    end
  end

  defp get_app(app_name) do
    App
    |> Repo.get_by(service_name: app_name)
    |> case do
      nil -> BusinessError.no_app_found_tuple()
      %App{} = app -> app
    end
  end

  defmodule Policy do
    @moduledoc """
      This policy defines the rules to join an application.
      The admin can join any app.
    """
    @behaviour Bouncer.Policy

    @impl true
    def authorize(_action, %User{role: :admin}, _metadata), do: true

    def authorize(:join_app, %User{id: id}, %App{creator_id: id}), do: true

    def authorize(:join_app, _user, %App{
          main_env: %MainEnv{environment: %Environment{is_public: true}}
        }),
        do: true

    def authorize(:join_app, user, app) do
      case Apps.fetch_user_env_access(
             environment_id: app.main_env.environment.id,
             user_id: user.id
           ) do
        {:ok, _access} -> true
        _any -> false
      end
    end

    def authorize(_action, _resource, _metadata), do: false
  end
end
