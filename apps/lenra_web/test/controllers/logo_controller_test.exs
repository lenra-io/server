defmodule LenraWeb.LogoControllerTest do
  alias Lenra.Apps.Image
  alias Lenra.Apps.Logo
  alias Lenra.Apps
  alias Lenra.Repo
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

  defp create_app(conn) do
    post(conn, Routes.apps_path(conn, :create), %{
      "name" => "test",
      "color" => "ffffff",
      "icon" => 12
    })
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
  end
end
