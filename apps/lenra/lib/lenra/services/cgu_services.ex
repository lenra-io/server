defmodule Lenra.CguServices do
  @moduledoc """
    The service that get the latest CGU.
  """

  import Ecto.Query, only: [from: 2, select: 3]

  alias Lenra.{Cgu, Repo, UserAcceptCguVersion}

  defp get_latest_cgu_query do
    Ecto.Query.last(Cgu, :inserted_at)
  end

  def get_latest_cgu do
    cgu = get_latest_cgu_query() |> Repo.one()

    case cgu do
      nil -> {:error, :error_404}
      cgu -> {:ok, cgu}
    end
  end

  def user_accepted_latest_cgu?(user_id) do
    latest_cgu = get_latest_cgu_query() |> select([c], c.id)

    with false <-
           Repo.exists?(
             from(
               u in Lenra.UserAcceptCguVersion,
               where: u.user_id == ^user_id and u.cgu_id in subquery(latest_cgu)
             )
           ) do
      not Repo.exists?(latest_cgu)
    end
  end

  def accept(cgu_id, user_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :accepted_cgu,
      UserAcceptCguVersion.new(%{cgu_id: cgu_id, user_id: user_id})
    )
    |> Repo.transaction()
  rescue
    Postgrex.Error -> {:error, :not_latest_cgu}
  end
end
