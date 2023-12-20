defmodule LenraWeb.BuildControllerTest do
  alias Lenra.Apps.Environment
  alias Lenra.Repo
  use LenraWeb.ConnCase, async: true

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
    end

    @tag auth_user_with_cgs: :dev
    test "env not existing logo", %{conn: conn!, png_image: png_image} do
      conn! = create_app(conn!)
      assert app = json_response(conn!, 200)

      env = Enum.at(Repo.all(Environment), 0)

      encoded_data = Base.encode64(png_image.data)

      conn! =
        put(
          conn!,
          Routes.logos_path(
            conn!,
            :put_logo,
            env.application_id,
            env.id
          ),
          %{"data" => encoded_data, "type" => png_image.type}
        )

      assert %{
               "application_id" => image_app_id,
               "environment_id" => image_env_id,
               "image_id" => 1
             } = json_response(conn!, 200)

      assert image_app_id == app["id"]
      assert image_env_id == env.id
    end
  end
end
