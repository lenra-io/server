defmodule Lenra.Legal do
  @moduledoc """
    This module handle all legal aspect for a user.
    - CGU acceptation
    - CGU creation
    - ...
  """

  import Ecto.Query, only: [from: 2, select: 3]

  alias Lenra.Legal.{CGU, UserAcceptCGUVersion}
  alias Lenra.Repo

  def get_latest_cgu do
    cgu = get_latest_cgu_query() |> Repo.one()

    case cgu do
      nil -> {:error, Lenra.Errors.error_404()}
      cgu -> {:ok, cgu}
    end
  end

  def user_accepted_latest_cgu?(user_id) do
    latest_cgu = get_latest_cgu_query() |> select([c], c.id)

    with false <-
           Repo.exists?(
             from(
               u in UserAcceptCGUVersion,
               where: u.user_id == ^user_id and u.cgu_id in subquery(latest_cgu)
             )
           ) do
      not Repo.exists?(latest_cgu)
    end
  end

  defp get_latest_cgu_query do
    Ecto.Query.last(CGU, :inserted_at)
  end

  def accept_cgu(cgu_id, user_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :accepted_cgu,
      UserAcceptCGUVersion.new(%{cgu_id: cgu_id, user_id: user_id})
    )
    |> Repo.transaction()
  rescue
    Postgrex.Error -> {:error, Lenra.Errors.not_latest_cgu()}
  end
end
