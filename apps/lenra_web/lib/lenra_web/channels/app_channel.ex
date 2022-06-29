defmodule LenraWeb.AppChannel do
  use ApplicationRunner.AppChannel

  alias Lenra.Accounts
  alias Lenra.Accounts.User
  alias Lenra.{Repo, UserEnvironmentAccessServices}
  alias Lenra.Apps.{App, Environment, MainEnv}

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
      case UserEnvironmentAccessServices.fetch_by(
             environment_id: app.main_env.environment.id,
             user_id: user.id
           ) do
        {:ok, _access} -> true
        _any -> false
      end
    end

    def authorize(_action, _resource, _metadata), do: false
  end

  defp allow(user_id, app_name) do
    with %App{} = application <- Repo.get_by(App, service_name: app_name),
         %User{} = user <- Accounts.get_user(user_id) do
      Bouncer.allow(LenraWeb.AppChannel.Policy, :join_app, user, application)
    else
      _err ->
        false
    end
  end

  defp get_function_name(app_name) do
    lenra_env = Application.fetch_env!(:lenra, :lenra_env)

    with %App{} = app <- Repo.get_by(App, service_name: app_name),
         %App{} = application <-
           Repo.preload(app, main_env: [environment: [:deployed_build]]) do
      build_number = application.main_env.environment.deployed_build.build_number
      %{function_name: String.downcase("#{lenra_env}-#{app_name}-#{build_number}")}
    end
  end

  defp get_env(app_name) do
    # Get first env for now
    application =
      App
      |> Repo.get_by(service_name: app_name)
      |> Repo.preload(:environments)

    List.first(application.environments).id
  end
end
