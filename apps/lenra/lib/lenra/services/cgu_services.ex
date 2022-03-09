defmodule Lenra.CguService do
  @moduledoc """
    The service that get the latest CGU.
  """
  alias Lenra.{Cgu, Repo}

  def get_latest_cgu do
    Cgu |> Ecto.Query.last(:inserted_at) |> Repo.one()
  end
end
