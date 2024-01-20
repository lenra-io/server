defmodule LenraWeb.LogoControllerTest do
  use LenraWeb.ConnCase, async: false
  alias Lenra.Apps
  alias Lenra.Apps.Image
  alias Lenra.Apps.Logo
  alias Lenra.Repo

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

  defp clean_repo do
    Repo.delete_all(Logo)
    Repo.delete_all(Image)
  end

  @tag auth_user_with_cgs: :dev
  describe "put" do
    test "app not existing logo", %{conn: conn!, png_image: png_image} do
      conn! = create_app(conn!)
      assert app = json_response(conn!, 200)

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
      clean_repo()
    end

    @tag :skip
    @tag auth_user_with_cgs: :dev
    test "env not existing logo", %{conn: conn!, png_image: png_image} do
      conn! = create_app(conn!)
      assert app = json_response(conn!, 200)

      {:ok, env} = Apps.fetch_main_env_for_app(app["id"])

      encoded_data = Base.encode64(png_image.data)

      conn! =
        put(
          conn!,
          Routes.logos_path(
            conn!,
            :put_logo,
            app["id"],
            env.id
          ),
          %{"data" => encoded_data, "type" => png_image.type}
        )

      assert %{
               "application_id" => image_app_id,
               "environment_id" => image_env_id,
               "image_id" => _
             } = json_response(conn!, 200)

      assert image_app_id == app["id"]
      assert image_env_id == env.id
      clean_repo()
    end

    @tag auth_users_with_cgs: [:dev, :user, :dev, :admin]
    test "logo controller authenticated", %{users: [creator!, user!, other_dev!, admin!], png_image: png_image} do
      creator! = create_app(creator!)
      assert app = json_response(creator!, 200)

      other_dev! = create_app(other_dev!, "test2")
      assert other_app = json_response(other_dev!, 200)

      [env] = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      update_app_logo_path = Routes.logos_path(creator!, :put_logo, app["id"], env["id"])
      update_env_logo_path = Routes.logos_path(creator!, :put_logo, app["id"], env["id"])
      update_other_env_logo_path = Routes.logos_path(creator!, :put_logo, other_app["id"], env["id"])

      encoded_data = Base.encode64(png_image.data)

      body = %{"data" => encoded_data, "type" => png_image.type}

      error_response = %{
        "message" => "Forbidden",
        "reason" => "forbidden"
      }

      assert %{"image_id" => _id} = json_response(put(creator!, update_app_logo_path, body), 200)
      assert %{"image_id" => _id} = json_response(put(creator!, update_env_logo_path, body), 200)
      assert %{"image_id" => _id} = json_response(put(admin!, update_app_logo_path, body), 200)
      assert %{"image_id" => _id} = json_response(put(admin!, update_env_logo_path, body), 200)

      assert ^error_response = json_response(put(user!, update_app_logo_path, body), 403)
      assert ^error_response = json_response(put(user!, update_env_logo_path, body), 403)
      assert ^error_response = json_response(put(other_dev!, update_app_logo_path, body), 403)
      assert ^error_response = json_response(put(other_dev!, update_env_logo_path, body), 403)
      assert ^error_response = json_response(put(creator!, update_other_env_logo_path, body), 403)
      assert ^error_response = json_response(put(other_dev!, update_other_env_logo_path, body), 403)
    end
  end
end
