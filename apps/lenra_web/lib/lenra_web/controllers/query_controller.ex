defmodule LenraWeb.QueryController do
  use LenraWeb, :controller

  def insert(conn, params) do
    # get app_id from conn
    app_id = conn.app.id

    with {:ok, inserted_data} <- ApplicationRunner.Query.insert(app_id, params) do
      conn
      |> assign_data(:inserted, inserted_data)
      |> reply
    else
      err -> IO.inspect(err)
    end
  end

  def insert_datastore(conn, params) do
    # get app_id from conn
    app_id = conn.app.id

    with {:ok, %{inserted_datastore: datastore}} <- ApplicationRunner.Query.create_table(app_id, params) do
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
