defmodule Lenra.CguService do
  @moduledoc """
    The service that get the latest CGU.
  """
  alias Lenra.{Cgu, Repo}

  def get_latest_cgu do
    cgu = Cgu |> Ecto.Query.last(:inserted_at) |> Repo.one()

    case cgu do
      nil -> {:error, :error_404}
      cgu -> {:ok, cgu}
    end
  end
end
