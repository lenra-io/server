defmodule LenraWeb.DatastoreController do
  use LenraWeb, :controller

  alias Lenra.AppGuardian.Plug
  alias Lenra.DatastoreServices

  def create(conn, params) do
    with session_assings <- Plug.current_resource(conn),
         {:ok, %{inserted_datastore: datastore}} <- DatastoreServices.create(session_assings.environment.id, params) do
      conn
      |> assign_data(:inserted_datastore, datastore)
      |> reply
    end
  end

  def delete(conn, params) do
    with session_assings <- Plug.current_resource(conn),
         {:ok, %{deleted_datastore: datastore}} <-
           DatastoreServices.delete(params["datastore"], session_assings.environment.id) do
      conn
      |> assign_data(:deleted_datastore, datastore)
      |> reply
    end
  end
end
