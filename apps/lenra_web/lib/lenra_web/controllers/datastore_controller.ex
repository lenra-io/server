defmodule LenraWeb.DatastoreController do
  use LenraWeb, :controller

  alias Lenra.DatastoreServices

  def create(conn, params) do
    with {:ok, inserted_datastore: datastore} <- DatastoreServices.create(params["env_id"], params) do
      conn
      |> assign_data(:datastore, datastore)
      |> reply
    end
  end

  def update(conn, params) do
    with {:ok, updated_datastore: datastore} <- DatastoreServices.update(params["datastore_id"], params) do
      conn
      |> assign_data(:datastore, datastore)
      |> reply
    end
  end

  def delete(conn, params) do
    with {:ok, deleted_datastore: datastore} <- DatastoreServices.delete(params["datastore_id"]) do
      conn
      |> assign_data(:datastore, datastore)
      |> reply
    end
  end
end
