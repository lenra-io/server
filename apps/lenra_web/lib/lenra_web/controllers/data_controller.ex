defmodule LenraWeb.DataController do
  use LenraWeb, :controller

  alias Lenra.AppGuardian.Plug
  alias Lenra.DataServices

  def get(conn, params) do
    with data <- DataServices.get(params["_datastore"], params["_id"]) do
      conn
      |> assign_data(:data, data)
      |> reply
    end
  end

  def create(conn, params) do
    with session_assings <- Plug.current_resource(conn),
         {:ok, %{inserted_data: data}} <-
           DataServices.create(session_assings.environment.id, params) do
      conn
      |> assign_data(:inserted_data, data)
      |> reply
    end
  end

  def update(conn, params) do
    with {:ok, %{updated_data: data}} <- DataServices.update(params) do
      conn
      |> assign_data(:updated_data, data)
      |> reply
    end
  end

  def delete(conn, params) do
    with {:ok, %{deleted_data: data}} <- DataServices.delete(params["_id"]) do
      conn
      |> assign_data(:deleted_data, data)
      |> reply
    end
  end

  def query(conn, params) do
    with session_assings <- Plug.current_resource(conn),
         requested <-
           DataServices.query(session_assings.environment.id, session_assings.user.id, params["query"]) do
      conn
      |> assign_data(:requested, requested)
      |> reply
    end
  end
end
