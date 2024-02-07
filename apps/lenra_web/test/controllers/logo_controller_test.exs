defmodule LenraWeb.LogoControllerTest do
  use LenraWeb.ConnCase, async: false

  setup %{conn: conn} do
    {:ok,
     conn: conn,
     png_image: %{
       data: File.read!(Application.app_dir(:identity_web, "/priv/static/images/appicon.png")),
       type: "image/png"
     },
     svg_image: %{
       data: File.read!(Application.app_dir(:identity_web, "/priv/static/images/logo.svg")),
       type: "image/svg+xml"
     }}
  end

  @tag auth_user_with_cgs: :dev
  describe "put" do
    test "app not existing logo", %{conn: conn!, png_image: png_image} do
      %{conn: conn!, app: app} = create_app(conn!)

      encoded_data = Base.encode64(png_image.data)

      conn! =
        put(
          conn!,
          Routes.logos_path(
            conn!,
            :put_logo,
            app["id"]
          ),
          %{"data" => encoded_data, "type" => png_image.type}
        )

      assert %{
               "application_id" => image_app_id,
               "environment_id" => nil,
               "image_id" => _
             } = json_response(conn!, 200)

      assert image_app_id == app["id"]
    end

    @tag auth_user_with_cgs: :dev
    test "env not existing logo", %{conn: conn!, png_image: png_image} do
      %{conn: conn!, app: app} = create_app(conn!)

      [env] = json_response(get(conn!, Routes.envs_path(conn!, :index, app["id"])), 200)

      encoded_data = Base.encode64(png_image.data)

      conn! =
        put(
          conn!,
          Routes.logos_path(
            conn!,
            :put_logo,
            app["id"],
            env["id"]
          ),
          %{"data" => encoded_data, "type" => png_image.type}
        )

      assert %{
               "application_id" => image_app_id,
               "environment_id" => image_env_id,
               "image_id" => _
             } = json_response(conn!, 200)

      assert image_app_id == app["id"]
      assert image_env_id == env["id"]
    end

    @tag auth_users_with_cgs: [:dev, :user, :dev, :admin]
    test "logo controller authenticated", %{users: [creator!, user!, other_dev!, admin!], png_image: png_image} do
      %{conn: creator!, app: app} = create_app(creator!)
      %{conn: other_dev!, app: other_app} = create_app(other_dev!, "test2")

      [env] = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      update_app_logo_path = Routes.logos_path(creator!, :put_logo, app["id"])
      update_env_logo_path = Routes.logos_path(creator!, :put_logo, app["id"], env["id"])
      update_other_env_logo_path = Routes.logos_path(creator!, :put_logo, other_app["id"], env["id"])

      encoded_data = Base.encode64(png_image.data)

      body = %{"data" => encoded_data, "type" => png_image.type}

      assert %{"image_id" => _id} = json_response(put(creator!, update_app_logo_path, body), 200)
      assert %{"image_id" => _id} = json_response(put(creator!, update_env_logo_path, body), 200)
      assert %{"image_id" => _id} = json_response(put(admin!, update_app_logo_path, body), 200)
      assert %{"image_id" => _id} = json_response(put(admin!, update_env_logo_path, body), 200)

      assert %{"message" => "Forbidden", "reason" => "forbidden"} =
               json_response(put(user!, update_app_logo_path, body), 403)

      assert %{"message" => "Forbidden", "reason" => "forbidden"} =
               json_response(put(user!, update_env_logo_path, body), 403)

      assert %{"message" => "Forbidden", "reason" => "forbidden"} =
               json_response(put(other_dev!, update_app_logo_path, body), 403)

      assert %{"message" => "Forbidden", "reason" => "forbidden"} =
               json_response(put(other_dev!, update_env_logo_path, body), 403)

      assert %{"message" => "Environment not found", "reason" => "no_env_found"} =
               json_response(put(creator!, update_other_env_logo_path, body), 404)

      assert %{"message" => "Environment not found", "reason" => "no_env_found"} =
               json_response(put(other_dev!, update_other_env_logo_path, body), 404)
    end
  end
end
