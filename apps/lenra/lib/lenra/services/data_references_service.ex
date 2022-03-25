defmodule Lenra.DataReferencesServices do
  @moduledoc """
    The service that manages the data reference.
  """

  alias ApplicationRunner.DataReferencesServices
  alias Lenra.Repo

  def create(params) do
    params
    |> DataReferencesServices.create()
    |> Repo.transaction()
  end

  def delete(params) do
    params
    |> DataReferencesServices.delete()
    |> Repo.transaction()
  end
end
