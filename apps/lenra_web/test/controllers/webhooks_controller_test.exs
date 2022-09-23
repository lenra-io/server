defmodule LenraWeb.WebhooksControllerTest do
  use LenraWeb.ConnCase, async: true

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
    ApplicationRunner.Webhooks.WebhookServices.create(env.id, %{"action" => "test"})

    conn = get(conn, Routes.webhooks_path(conn, :index), %{"env_id" => env.id})

    assert [webhook] = json_response(conn, 200)
    assert webhook["action"] == "test"
    assert webhook["environment_id"] == env.id
  end

  @tag auth_user_with_cgu: :dev
  test "Get session webhooks should work properly", %{conn: conn, user: user, env: env} do
    ApplicationRunner.Webhooks.WebhookServices.create(env.id, %{
      "action" => "test",
      "user_id" => user.id
    })

    conn =
      get(conn, Routes.webhooks_path(conn, :index), %{"env_id" => env.id, "user_id" => user.id})

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
end
