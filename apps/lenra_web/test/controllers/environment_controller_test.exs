defmodule LenraWeb.EnvironmentControllerTest do
  use LenraWeb.ConnCase, async: false

  alias Lenra.Repo
  alias Lenra.Subscriptions.Subscription

  setup %{conn: conn} do
    {:ok, conn: conn}
  end

  describe "index" do
    test "environment controller not authenticated", %{conn: conn} do
      conn = get(conn, Routes.envs_path(conn, :index, 0))

      assert json_response(conn, 401) == %{
               "message" => "No Bearer token found in Authorization header",
               "reason" => "token_not_found",
               "metadata" => %{}
             }
    end

    @tag auth_users_with_cgs: [:dev, :user, :dev, :admin]
    test "get environment check authorizations", %{users: [creator!, user, other_dev, admin]} do
      creator! = create_app(creator!)

      assert app = json_response(creator!, 200)

      creator! =
        post(creator!, Routes.envs_path(creator!, :create, app["id"]), %{
          "name" => "test",
          "is_ephemeral" => false,
          "is_public" => false
        })

      get_route_name = Routes.envs_path(creator!, :index, app["id"])
      user = get(user, get_route_name)
      other_dev = get(other_dev, get_route_name)
      admin = get(admin, get_route_name)
      creator! = get(creator!, get_route_name)

      assert [
               %{
                 "is_ephemeral" => false,
                 "is_public" => false,
                 "name" => "live",
                 "application_id" => _,
                 "creator_id" => _,
                 "deployment_id" => _,
                 "id" => _
               },
               %{
                 "is_ephemeral" => false,
                 "is_public" => false,
                 "name" => "test",
                 "application_id" => _,
                 "creator_id" => _,
                 "deployment_id" => _,
                 "id" => _
               }
             ] = json_response(creator!, 200)

      assert [
               %{
                 "is_ephemeral" => false,
                 "is_public" => false,
                 "name" => "live",
                 "application_id" => _,
                 "creator_id" => _,
                 "deployment_id" => _,
                 "id" => _
               },
               %{
                 "is_ephemeral" => false,
                 "is_public" => false,
                 "name" => "test",
                 "application_id" => _,
                 "creator_id" => _,
                 "deployment_id" => _,
                 "id" => _
               }
             ] = json_response(admin, 200)

      assert %{
               "message" => "Forbidden",
               "reason" => "forbidden"
             } = json_response(user, 403)

      assert %{
               "message" => "Forbidden",
               "reason" => "forbidden"
             } = json_response(other_dev, 403)
    end
  end

  describe "update" do
    @tag auth_users_with_cgs: [:dev, :user, :dev, :admin]
    test "environment controller authenticated", %{users: [creator!, user!, other_dev!, admin!]} do
      creator! = create_app(creator!)
      assert app = json_response(creator!, 200)

      other_dev! = create_app(other_dev!, "test2")
      assert other_app = json_response(other_dev!, 200)

      [env] = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      update_env_path = Routes.envs_path(creator!, :update, app["id"], env["id"])
      update_other_app_env_path = Routes.envs_path(other_dev!, :update, other_app["id"], env["id"])

      public_body = %{
        "is_public" => true
      }

      private_body = %{
        "is_public" => false
      }

      creator! = patch(creator!, update_env_path, public_body)

      assert %{"message" => "You need a subscirption", "reason" => "subscription_required"} =
               json_response(creator!, 402)

      assert [^private_body] = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      subscription =
        Subscription.new(%{
          application_id: app["id"],
          start_date: DateTime.utc_now(),
          end_date: DateTime.utc_now() |> DateTime.add(1000, :second),
          plan: "month"
        })

      Repo.insert(subscription)

      forbidden_error = %{"message" => "Forbidden", "reason" => "forbidden"}

      creator! = patch(creator!, update_env_path, public_body)
      assert [^public_body] = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      patch(admin!, update_env_path, private_body)
      assert [^private_body] = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      user! = patch(user!, update_env_path, public_body)
      assert ^forbidden_erro = json_response(user!, 403)

      assert [^private_body] = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      other_dev! = patch(other_dev!, update_env_path, public_body)
      assert ^forbidden_erro = json_response(other_dev!, 403)

      assert [^private_body] = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)
      assert ^forbidden_erro = json_response(patch(creator!, update_other_app_env_path, private_body), 403)
      assert ^forbidden_erro = json_response(patch(other_dev!, update_other_app_env_path, private_body), 403)
    end
  end

  describe "create" do
    @tag auth_users_with_cgs: [:dev, :user, :dev, :admin]
    test "environment controller authenticated", %{users: [creator!, user!, other_dev!, admin!]} do
      creator! = create_app(creator!)
      assert app = json_response(creator!, 200)

      create_env_path = Routes.envs_path(creator!, :create, app["id"])

      post(creator!, create_env_path, %{
        "name" => "test_creator",
        "is_ephemeral" => false,
        "is_public" => false
      })

      post(admin!, create_env_path, %{
        "name" => "test_admin",
        "is_ephemeral" => false,
        "is_public" => false
      })

      user! =
        post(user!, create_env_path, %{
          "name" => "test_user",
          "is_ephemeral" => false,
          "is_public" => false
        })

      other_dev! =
        post(other_dev!, create_env_path, %{
          "name" => "test_other_dev",
          "is_ephemeral" => false,
          "is_public" => false
        })

      assert ^forbidden_erro = json_response(user!, 403)
      assert ^forbidden_erro = json_response(other_dev!, 403)
    end

    @tag auth_user_with_cgs: :dev
    test "environment controller authenticated but invalid params", %{conn: conn!} do
      conn! = create_app(conn!)

      assert app = json_response(conn!, 200)

      conn! =
        post(conn!, Routes.envs_path(conn!, :create, app["id"]), %{
          "name" => 1234,
          "is_ephemeral" => "false",
          "is_public" => false
        })

      assert %{"message" => "name is invalid", "reason" => "invalid_name"} = json_response(conn!, 400)
    end
  end
end
