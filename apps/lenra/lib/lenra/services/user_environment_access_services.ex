defmodule Lenra.UserEnvironmentAccessServices do
  @moduledoc """
    The service that manages the different possible actions on an environment's user accesses.
  """
  import Ecto.Query
  alias Lenra.{Repo, UserEnvironmentAccess}
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
    |> Repo.transaction()
  end

  def delete(user_access) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:deleted_user_access, user_access)
  end
end
