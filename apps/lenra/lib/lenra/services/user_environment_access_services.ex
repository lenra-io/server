defmodule Lenra.UserEnvironmentAccessServices do
  @moduledoc """
    The service that manages the different possible actions on an environment's user accesses.
  """
  import Ecto.Query
  alias Lenra.{EmailWorker, EnvironmentServices, Repo, UserEnvironmentAccess, UserServices}
  require Logger

  def all(env_id) do
    Repo.all(from(e in UserEnvironmentAccess, where: e.environment_id == ^env_id))
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

      add_invitation_events(user, env.application.name, "TODO")
    end)
    |> Repo.transaction()
  end

  defp add_invitation_events(user, application_name, app_link) do
    EmailWorker.add_email_invitation_event(user, application_name, app_link)
  end

  def delete(user_access) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:deleted_user_access, user_access)
  end
end
