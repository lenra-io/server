defmodule LenraWeb.DataReferenceController do
  use LenraWeb, :controller

  alias Lenra.DataReferencesServices

  def create(conn, params) do
    with {:ok, inserted_reference: reference} <- DataReferencesServices.create(params) do
      conn
      |> assign_data(:reference, reference)
      |> reply
    end
  end

  def delete(conn, params) do
    with {:ok, deleted_reference: reference} <- DataReferencesServices.delete(params) do
      conn
      |> assign_data(:reference, reference)
      |> reply
    end
  end
end
