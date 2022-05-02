defmodule Lenra.UserDataServices do
  @moduledoc """
    The service that manages application data.
  """

  alias ApplicationRunner.UserDataServices
  alias Lenra.Repo

  def has_user_data?(env_id, user_id) do
    env_id
    |> UserDataServices.current_user_data_query(user_id)
    |> Repo.exists?()
  end

  def create_user_data(env_id, user_id) do
    env_id
    |> UserDataServices.create_with_data(user_id)
    |> Repo.transaction()
  end
end
