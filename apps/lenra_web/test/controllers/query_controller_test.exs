defmodule LenraWeb.QueryControllerTest do
  use LenraWeb.ConnCase, async: true

  setup %{conn: conn} do
    {:ok, conn: conn}
  end

  describe "QueryController.insert_datastore_1/1" do
    @tag auth_user: :dev
    test "request with valid params should retrun inserted_data", %{conn: conn} do
      user_id = conn.assigns.user.id

      conn =
        post(
          conn,
          Routes.apps_path(conn, :create, %{
            "name" => "test",
            "service_name" => "test",
            "color" => "ffffff",
            "icon" => 31,
            "creator_id" => user_id
          })
        )

      app = conn.assigns.data.app

      conn =
        conn
        |> recycle()
        |> Map.put(:app, app)

      conn = post(conn, Routes.query_path(Plug.Conn.assign(conn, :app, app), :insert_datastore, %{"name" => "test"}))

      assert %{"data" => _data, "success" => true} = json_response(conn, 200)
    end

    @tag auth_user: :dev
    test "request with invalid json params should retrun error", %{conn: conn} do
      user_id = conn.assigns.user.id

      conn =
        post(
          conn,
          Routes.apps_path(conn, :create, %{
            "name" => "test",
            "service_name" => "test",
            "color" => "ffffff",
            "icon" => 31,
            "creator_id" => user_id
          })
        )

      app = conn.assigns.data.app

      conn =
        conn
        |> recycle()
        |> Map.put(:app, app)

      conn = post(conn, Routes.query_path(conn, :insert_datastore, %{"test" => "test"}))

      assert %{"errors" => [%{"code" => 15, "message" => "Json format are not valid"}], "success" => false} =
               json_response(conn, 400)
    end
  end

  describe "QueryController.insert_1/1" do
    @tag auth_user: :dev
    test "request with valid params should return data", %{conn: conn} do
      user_id = conn.assigns.user.id

      conn =
        post(
          conn,
          Routes.apps_path(conn, :create, %{
            "name" => "test",
            "service_name" => "test",
            "color" => "ffffff",
            "icon" => 31,
            "creator_id" => user_id
          })
        )

      app = conn.assigns.data.app

      conn =
        conn
        |> recycle()
        |> Map.put(:app, app)

      conn = post(conn, Routes.query_path(conn, :insert_datastore, %{"name" => "test"}))

      conn =
        conn
        |> recycle()
        |> Map.put(:app, app)

      conn = post(conn, Routes.query_path(conn, :insert, %{"table" => "test", "data" => %{"name" => "test"}}))

      assert %{"data" => _data, "success" => true} = json_response(conn, 200)
    end

    @tag auth_user: :dev
    test "request with invalid params should return error", %{conn: conn} do
      user_id = conn.assigns.user.id

      conn =
        post(
          conn,
          Routes.apps_path(conn, :create, %{
            "name" => "test",
            "service_name" => "test",
            "color" => "ffffff",
            "icon" => 31,
            "creator_id" => user_id
          })
        )

      app = conn.assigns.data.app

      conn =
        conn
        |> recycle()
        |> Map.put(:app, app)

      conn = post(conn, Routes.query_path(conn, :insert, %{"table" => "test", "data" => %{"name" => "test"}}))

      assert %{
               "errors" => [%{"code" => 18, "message" => "You attempt add data on unknow datastore"}],
               "success" => false
             } = json_response(conn, 400)
    end
  end

  describe "Query.update_1/1" do
    @tag auth_user: :dev

    test "request with correct params should return updated_data", %{conn: conn} do
      user_id = conn.assigns.user.id

      conn =
        post(
          conn,
          Routes.apps_path(conn, :create, %{
            "name" => "test",
            "service_name" => "test",
            "color" => "ffffff",
            "icon" => 31,
            "creator_id" => user_id
          })
        )

      app = conn.assigns.data.app

      conn =
        conn
        |> recycle()
        |> Map.put(:app, app)

      post(conn, Routes.query_path(conn, :insert_datastore, %{"name" => "test"}))
      conn = post(conn, Routes.query_path(conn, :insert, %{"table" => "test", "data" => %{"name" => "test"}}))

      data_id = conn.assigns.data.inserted.inserted_data.id

      conn = put(conn, Routes.query_path(conn, :update, %{"id" => data_id, "data" => %{"name" => "newTest"}}))

      assert %{"data" => data, "success" => true} = json_response(conn, 200)
      assert data["updated_data"]["data"] == %{"name" => "newTest"}
    end
  end
end
