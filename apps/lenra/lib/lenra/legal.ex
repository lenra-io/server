defmodule Lenra.Legal do
  @moduledoc """
    This module handle all legal aspect for a user.
    - CGS acceptation
    - CGS creation
    - ...
  """

  import Ecto.Query, only: [from: 2, select: 3]

  alias Lenra.Errors.{BusinessError, TechnicalError}
  alias Lenra.Legal
  alias Lenra.Legal.{CGS, UserAcceptCGSVersion}
  alias Lenra.Repo
  alias Lenra.Utils

  def get_latest_cgs do
    cgs = get_latest_cgs_query() |> Repo.one()

    case cgs do
      nil -> TechnicalError.cgs_not_found_tuple()
      cgs -> {:ok, cgs}
    end
  end

  def user_accepted_latest_cgs?(user_id) do
    latest_cgs = get_latest_cgs_query() |> select([c], c.id)

    with false <-
           Repo.exists?(
             from(
               u in UserAcceptCGSVersion,
               where: u.user_id == ^user_id and u.cgs_id in subquery(latest_cgs)
             )
           ) do
      not Repo.exists?(latest_cgs)
    end
  end

  defp get_latest_cgs_query do
    Ecto.Query.last(CGS, :inserted_at)
  end

  def accept_cgs(cgs_id, user_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :accepted_cgs,
      UserAcceptCGSVersion.new(%{cgs_id: cgs_id, user_id: user_id})
    )
    |> Repo.transaction()
  rescue
    Postgrex.Error -> BusinessError.not_latest_cgs_tuple()
  end

  def add_cgs(path, version) do
    hash = to_string(Utils.hash_file(path, :sha256))

    %{path: path, version: version, hash: hash}
    |> Legal.CGS.new()
    |> Repo.insert(on_conflict: :nothing)
  end
end
