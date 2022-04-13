defmodule LenraWeb.DataController do
  use LenraWeb, :controller

  alias Lenra.AppGuardian.Plug
  alias Lenra.DataServices

  def create(conn, params) do
    with {:ok, inserted_data: data} <-
           DataServices.create(Plug.current_resource(conn).environment.id, params) do
      conn
      |> assign_data(:inserted_data, data)
      |> reply
    end
  end

  def update(conn, params) do
    with {:ok, updated_data: data} <- DataServices.update(params["data_id"], params) do
      conn
      |> assign_data(:updated_data, data)
      |> reply
    end
  end

  def delete(conn, params) do
    with {:ok, deleted_data: data} <- DataServices.delete(params["data_id"]) do
      conn
      |> assign_data(:deleted_data, data)
      |> reply
    end
  end

  def query(conn, params) do
  end
end
