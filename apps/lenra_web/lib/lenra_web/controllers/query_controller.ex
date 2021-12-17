defmodule LenraWeb.QueryController do
  use LenraWeb, :controller

  def insert(conn, params) do
    with {:ok, inserted_data} <- ApplicationRunner.Query.insert(params) do
      IO.puts(inspect(inserted_data))

      conn
      |> assign_data(:inserted, inserted_data)
      |> reply
    end
  end

  def insert_datastore(conn, params) do
    with {:ok, %{inserted_datastore: datastore}} <- ApplicationRunner.Query.insert(params) do
      conn
      |> assign_data(:inserted_datastore, datastore)
      |> reply
    end
  end

  def update(conn, params) do
    with {:ok, updated_data} <- ApplicationRunner.Query.update(params) do
      conn
      |> assign_data(:updated_data, updated_data)
      |> reply
    end
  end

  def delete(conn, params) do
    with {:ok, _} <- ApplicationRunner.Query.delete(params) do
      conn
      |> reply
    end
  end
end
