defmodule LenraWeb.OAuth2ControllerTest do
  @moduledoc """
    Test the `LenraWeb.OAuth2ControllerTest` module
  """
  use LenraWeb.ConnCase, async: false

  defp create_app_test(conn) do
    post(
      conn,
      Routes.apps_path(conn, :create, %{
        "name" => "test",
        "color" => "ffffff",
        "icon" => 31,
        "repository" => "http://repository.com/link.git",
        "repository_branch" => "master"
      })
    )
  end

  defp stub_hydra(%{hydra_bypass: hydra_bypass, env_id: env_id}) do
    Bypass.expect(hydra_bypass, fn
      %Plug.Conn{method: "POST", request_path: "/admin/oauth2/introspect"} = conn ->
        LenraWeb.ConnCase.hydra_introspect_response(conn)

      %Plug.Conn{method: "POST", request_path: "/admin/clients"} = conn ->
        resp = %{
          client_id: "a-valid-uuid",
          client_secret: "maybe_a_valid_secret",
          client_secret_expires_at: 42
        }

        Plug.Conn.resp(conn, 200, Jason.encode!(resp))

      %Plug.Conn{method: "PUT", request_path: "/admin/clients/a-valid-uuid"} = conn ->
        resp = %{
          client_id: "a-valid-uuid",
          scope: "profile store",
          allowed_cors_origins: ["http://localhost:10000"],
          redirect_uris: ["http://localhost:10000/redirect.html"],
          client_name: "Bar",
          metadata: %{
            environment_id: env_id
          }
        }

        Plug.Conn.resp(conn, 200, Jason.encode!(resp))

      %Plug.Conn{method: "GET", request_path: "/admin/clients/a-valid-uuid"} = conn ->
        resp = %{
          client_id: "a-valid-uuid",
          scope: "profile store",
          allowed_cors_origins: ["http://localhost:10000"],
          redirect_uris: ["http://localhost:10000/redirect.html"],
          client_name: "Foo",
          metadata: %{
            environment_id: env_id
          }
        }

        Plug.Conn.resp(conn, 200, Jason.encode!(resp))

      %Plug.Conn{method: "DELETE", request_path: "/admin/clients/a-valid-uuid"} = conn ->
        Plug.Conn.resp(conn, 204, "")
    end)

    Bypass.pass(hydra_bypass)
  end

  setup %{conn: conn} do
    %{"id" => app_id} = conn |> create_app_test() |> json_response(200)
    {:ok, %{id: env_id}} = Lenra.Apps.fetch_main_env_for_app(app_id)
    {:ok, conn: conn, env_id: env_id}
  end

  describe "create a new OAuth client" do
    @tag auth_user_with_cgu: :dev
    test "Create a simple oauth client", %{conn: conn, env_id: env_id} = ctx do
      stub_hydra(ctx)
      route = Routes.o_auth2_path(conn, :create, env_id)

      params = %{
        "name" => "Foo",
        "scopes" => ["profile", "store"],
        "redirect_uris" => ["http://localhost:10000/redirect.html"],
        "allowed_origins" => ["http://localhost:10000"]
      }

      conn = post(conn, route, params)

      assert %{
               "client" => %{
                 "allowed_origins" => ["http://localhost:10000"],
                 "environment_id" => ^env_id,
                 "name" => "Foo",
                 "oauth2_client_id" => "a-valid-uuid",
                 "redirect_uris" => ["http://localhost:10000/redirect.html"],
                 "scopes" => ["profile", "store"]
               },
               "secret" => %{"expiration" => 42, "value" => "maybe_a_valid_secret"}
             } = json_response(conn, 200)
    end

    @tag auth_user_with_cgu: :dev
    test "Create a simple oauth client : Wrong scopes", %{conn: conn, env_id: env_id} = ctx do
      stub_hydra(ctx)
      route = Routes.o_auth2_path(conn, :create, env_id)

      params = %{
        "name" => "Foo",
        "scopes" => ["profiles", "store"],
        "redirect_uris" => ["http://localhost:10000/redirect.html"],
        "allowed_origins" => ["http://localhost:10000"]
      }

      conn = post(conn, route, params)

      assert %{
               "message" => "scopes has an invalid entry",
               "reason" => "invalid_scopes"
             } = json_response(conn, 400)
    end

    @tag auth_user_with_cgu: :dev
    test "Create a simple oauth client : Wrong redirect_uris",
         %{conn: conn, env_id: env_id} = ctx do
      stub_hydra(ctx)
      route = Routes.o_auth2_path(conn, :create, env_id)

      params = %{
        "name" => "Foo",
        "scopes" => ["profile", "store"],
        "redirect_uris" => ["wrong_url"],
        "allowed_origins" => ["http://localhost:10000"]
      }

      conn = post(conn, route, params)

      assert %{
               "message" => "redirect_uris has an invalid format",
               "reason" => "invalid_redirect_uris"
             } = json_response(conn, 400)
    end

    @tag auth_user_with_cgu: :dev
    test "Create a simple oauth client : Wrong allowed_origins",
         %{conn: conn, env_id: env_id} = ctx do
      stub_hydra(ctx)
      route = Routes.o_auth2_path(conn, :create, env_id)

      params = %{
        "name" => "Foo",
        "scopes" => ["profile", "store"],
        "redirect_uris" => ["http://localhost:4000/redirect.html"],
        "allowed_origins" => ["wrong_url"]
      }

      conn = post(conn, route, params)

      assert %{
               "message" => "allowed_origins has an invalid format",
               "reason" => "invalid_allowed_origins"
             } = json_response(conn, 400)
    end

    @tag auth_user_with_cgu: :dev
    test "Create a simple oauth client : Wrong name", %{conn: conn, env_id: env_id} = ctx do
      stub_hydra(ctx)
      route = Routes.o_auth2_path(conn, :create, env_id)

      params = %{
        "name" => "f",
        "scopes" => ["profile", "store"],
        "redirect_uris" => ["http://localhost:4000/redirect.html"],
        "allowed_origins" => ["http://localhost:4000"]
      }

      conn = post(conn, route, params)

      assert %{
               "message" => "name should be at least 3 character(s)",
               "reason" => "invalid_name"
             } = json_response(conn, 400)
    end
  end

  describe "Get client details" do
    @tag auth_user_with_cgu: :dev
    test "Get the oauth client", %{conn: conn, env_id: env_id} = ctx do
      stub_hydra(ctx)
      # Setup, create the client

      params = %{
        "name" => "Foo",
        "scopes" => ["profile", "store"],
        "redirect_uris" => ["http://localhost:10000/redirect.html"],
        "allowed_origins" => ["http://localhost:10000"],
        "environment_id" => env_id
      }

      {:ok, _} = Lenra.Apps.create_oauth2_client(params)

      # Get the clients

      route = Routes.o_auth2_path(conn, :index, env_id)
      conn = get(conn, route)

      assert [
               %{
                 "allowed_origins" => ["http://localhost:10000"],
                 "environment_id" => ^env_id,
                 "name" => "Foo",
                 "oauth2_client_id" => "a-valid-uuid",
                 "redirect_uris" => ["http://localhost:10000/redirect.html"],
                 "scopes" => ["profile", "store"]
               }
             ] = json_response(conn, 200)
    end
  end

  describe "Update oauth client" do
    @tag auth_user_with_cgu: :dev
    test "Update the oauth client", %{conn: conn, env_id: env_id} = ctx do
      stub_hydra(ctx)

      # create the client
      params = %{
        "name" => "Foo",
        "scopes" => ["profile", "store"],
        "redirect_uris" => ["http://localhost:10000/redirect.html"],
        "allowed_origins" => ["http://localhost:10000"],
        "environment_id" => env_id
      }

      {:ok, %{client: %{oauth2_client_id: client_id}}} = Lenra.Apps.create_oauth2_client(params)

      # Update the clients
      updated_params = Map.put(params, "name", "Bar")
      route = Routes.o_auth2_path(conn, :update, env_id, client_id)
      conn = put(conn, route, updated_params)

      assert %{
               "allowed_origins" => ["http://localhost:10000"],
               "environment_id" => ^env_id,
               "name" => "Bar",
               "oauth2_client_id" => "a-valid-uuid",
               "redirect_uris" => ["http://localhost:10000/redirect.html"],
               "scopes" => ["profile", "store"]
             } = json_response(conn, 200)
    end
  end

  describe "Delete oauth client" do
    @tag auth_user_with_cgu: :dev
    test "Delete the oauth client", %{conn: conn, env_id: env_id} = ctx do
      stub_hydra(ctx)

      # create the client
      params = %{
        "name" => "Foo",
        "scopes" => ["profile", "store"],
        "redirect_uris" => ["http://localhost:10000/redirect.html"],
        "allowed_origins" => ["http://localhost:10000"],
        "environment_id" => env_id
      }

      {:ok, %{client: %{oauth2_client_id: client_id}}} = Lenra.Apps.create_oauth2_client(params)

      # delete the clients
      route = Routes.o_auth2_path(conn, :delete, env_id, client_id)
      conn = delete(conn, route)

      assert %{"oauth2_client_id" => "a-valid-uuid", "environment_id" => ^env_id} = json_response(conn, 200)
    end
  end
end
