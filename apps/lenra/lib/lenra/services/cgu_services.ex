defmodule Lenra.CguService do
  @moduledoc """
    The service that get the latest CGU.
  """
  import Ecto.Query, only: [from: 2]

  alias Lenra.{Cgu, Repo}

  def get_latest_cgu do
    cgu = Cgu |> Ecto.Query.last(:inserted_at) |> Repo.one()

    case cgu do
      nil -> {:error, :error_404}
      cgu -> {:ok, cgu}
    end
  end

  def user_accepted_latest_cgu?(user_id) do
    latest_accepted_cgu_id =
      from(c in Cgu,
        join: u in Lenra.UserAcceptCguVersion,
        on: c.id == u.cgu_id,
        where: u.user_id == ^user_id,
        order_by: [desc: c.inserted_at],
        limit: 1,
        select: c.id
      )
      |> Repo.one()

    latest_cgu_id =
      from(c in Cgu, order_by: [desc: c.inserted_at], limit: 1, select: c.id)
      |> Repo.one()

    latest_accepted_cgu_id == latest_cgu_id
  end
end
