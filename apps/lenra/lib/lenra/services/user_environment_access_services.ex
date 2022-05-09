defmodule Lenra.UserEnvironmentAccessServices do
  @moduledoc """
    The service that manages the different possible actions on an environment's user accesses.
  """
  import Ecto.Query
  alias Lenra.{EmailWorker, EnvironmentServices, Repo, UserEnvironmentAccess, UserServices}
  require Logger

  @app_url_prefix Application.compile_env!(:lenra_web, :app_url_prefix)

  def all(env_id) do
    Repo.all(from(e in UserEnvironmentAccess, where: e.environment_id == ^env_id))
  end

  def fetch_by(clauses, error \\ {:error, :error_404}) do
    Repo.fetch_by(UserEnvironmentAccess, clauses, error)
  end

  def create(env_id, %{"user_id" => user_id}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :inserted_user_access,
      UserEnvironmentAccess.changeset(%UserEnvironmentAccess{}, %{user_id: user_id, environment_id: env_id})
    )
    |> Ecto.Multi.run(:add_invitation_event, fn repo, %{inserted_user_access: _} ->
      env = EnvironmentServices.get(env_id)
      user = UserServices.get(user_id)

      env = repo.preload(env, :application)

      app_link = "#{@app_url_prefix}/#{env.application.service_name}"

      add_invitation_events(user, env.application.name, app_link)
    end)
    |> Repo.transaction()
  end

  def add_user_env_access_from_email(env_id, %{"email" => email}) do
    {:ok, user} = Lenra.Repo.fetch_by(Lenra.User, email: email)
    create(env_id, %{"user_id" => user.id})
  end

  defp add_invitation_events(user, application_name, app_link) do
    EmailWorker.add_email_invitation_event(user, application_name, app_link)
  end

  def delete(user_access) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:deleted_user_access, user_access)
  end
end
