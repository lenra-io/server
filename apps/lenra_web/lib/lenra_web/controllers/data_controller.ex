defmodule LenraWeb.DataController do
  use LenraWeb, :controller

  alias Lenra.DataServices

  def create(conn, params) do
    with {:ok, inserted_data: data} <- DataServices.create(params["env_id"], params) do
      conn
      |> assign_data(:data, data)
      |> reply
    end
  end

  def update(conn, params) do
    with {:ok, updated_data: data} <- DataServices.update(params["data_id"], params) do
      conn
      |> assign_data(:data, data)
      |> reply
    end
  end

  def delete(conn, params) do
    with {:ok, deleted_data: data} <- DataServices.delete(params["data_id"]) do
      conn
      |> assign_data(:data, data)
      |> reply
    end
  end
end
