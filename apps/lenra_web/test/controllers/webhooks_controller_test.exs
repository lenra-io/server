defmodule LenraWeb.WebhooksControllerTest do
  use LenraWeb.ConnCase, async: true

  alias ApplicationRunner.Webhooks.WebhookServices

  setup %{conn: conn} do
    conn = create_app(conn)
    user = Guardian.Plug.current_resource(conn)

    assert app = json_response(conn, 200)

    {:ok, %{inserted_env: env}} =
      Lenra.Apps.create_env(app["id"], user.id, %{
        "name" => "test",
        "is_ephemeral" => false,
        "is_public" => false
      })

    {:ok, %{conn: conn, user: user, env: env}}
  end

  defp create_app(conn) do
    post(conn, Routes.apps_path(conn, :create), %{
      "name" => "test",
      "color" => "ffffff",
      "icon" => 12
    })
  end

  @tag auth_user_with_cgu: :dev
  test "Get env webhooks should work properly", %{conn: conn, env: env} do
    WebhookServices.create(env.id, %{"action" => "test"})

    conn = get(conn, Routes.webhooks_path(conn, :index), %{"env_id" => env.id})

    assert [webhook] = json_response(conn, 200)
    assert webhook["action"] == "test"
    assert webhook["environment_id"] == env.id
  end

  @tag auth_user_with_cgu: :dev
  test "Get session webhooks should work properly", %{conn: conn, user: user, env: env} do
    WebhookServices.create(env.id, %{
      "action" => "test",
      "user_id" => user.id
    })

    conn = get(conn, Routes.webhooks_path(conn, :index), %{"env_id" => env.id, "user_id" => user.id})

    assert [webhook] = json_response(conn, 200)
    assert webhook["action"] == "test"
    assert webhook["environment_id"] == env.id
    assert webhook["user_id"] == user.id
  end

  @tag auth_user_with_cgu: :dev
  test "Get with no webhooks in db should work properly", %{conn: conn, env: env} do
    conn = get(conn, Routes.webhooks_path(conn, :index), %{"env_id" => env.id})

    assert [] == json_response(conn, 200)
  end

  @tag auth_user_with_cgu: :dev
  test "Create webhook should work properly", %{conn: conn, user: user, env: env} do
    conn =
      post(conn, Routes.webhooks_path(conn, :api_create), %{
        "env_id" => env.id,
        "action" => "test",
        "user_id" => user.id
      })

    assert %{"action" => "test"} = json_response(conn, 200)

    conn! = get(conn, Routes.webhooks_path(conn, :index), %{"env_id" => env.id})

    assert [webhook] = json_response(conn!, 200)
    assert webhook["action"] == "test"
    assert webhook["environment_id"] == env.id
  end

  @tag auth_user_with_cgu: :dev
  test "Create webhook without env_id as parameter should fail", %{conn: conn, user: user} do
    conn =
      post(conn, Routes.webhooks_path(conn, :api_create), %{
        "action" => "test",
        "user_id" => user.id
      })

    assert %{"reason" => "null_parameters"} = json_response(conn, 400)
  end

  defp handle_request(conn, callback) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)

    body_decoded =
      if String.length(body) != 0 do
        Jason.decode!(body)
      else
        ""
      end

    callback.(body_decoded)

    case body_decoded do
      # Listeners "action" in body
      %{"action" => _action} ->
        Plug.Conn.resp(conn, 200, "")
    end
  end

  @tag auth_user_with_cgu: :dev
  test "Trigger webhook in env should work properly", %{conn: conn, env: env} do
    token = env.id |> ApplicationRunner.AppSocket.do_create_env_token() |> elem(1)

    env_metadata = %ApplicationRunner.Environment.Metadata{
      env_id: env.id,
      function_name: "test",
      token: token
    }

    {:ok, _} = start_supervised({ApplicationRunner.Environment.MetadataAgent, env_metadata})

    {:ok, webhook} =
      WebhookServices.create(env.id, %{
        "action" => "test"
      })

    bypass = Bypass.open(port: 1234)

    Bypass.stub(
      bypass,
      "POST",
      "/function/test",
      &handle_request(&1, fn body ->
        assert body["props"] == nil
        assert body["action"] == "test"
        assert body["event"] == %{"payloadData" => "Value"}
      end)
    )

    conn =
      conn
      |> post(
        Routes.webhooks_path(conn, :trigger, conn.assigns.root.service_name, webhook.uuid),
        %{
          "payloadData" => "Value"
        }
      )

    assert _res = json_response(conn, 200)
  end

  @tag auth_user_with_cgu: :dev
  test "Trigger webhook with not related app_uuid/webhook_uuid should return 404", %{
    conn: conn,
    env: env
  } do
    {:ok, webhook} =
      WebhookServices.create(env.id, %{
        "action" => "test"
      })

    conn =
      conn
      |> post(Routes.webhooks_path(conn, :trigger, Ecto.UUID.generate(), webhook.uuid), %{
        "payloadData" => "Value"
      })

    assert %{"message" => "Not Found.", "reason" => "error_404"} = json_response(conn, 404)
  end

  @tag auth_user_with_cgu: :dev
  test "Trigger webhook that does not exist should return 404", %{conn: conn, env: env} do
    conn =
      conn
      |> post(Routes.webhooks_path(conn, :trigger, Ecto.UUID.generate(), Ecto.UUID.generate()), %{
        "payloadData" => "Value"
      })

    assert %{"message" => "Not Found.", "reason" => "error_404"} = json_response(conn, 404)
  end
end
