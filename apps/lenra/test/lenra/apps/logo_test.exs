defmodule Lenra.Apps.LogoTest do
  @moduledoc """
    Test the logo services
  """
  use Lenra.RepoCase, async: false

  alias Lenra.Apps
  alias Lenra.Apps.Logo
  alias Lenra.Repo

  setup do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
    {:ok, %{inserted_application: app, inserted_env: env}} = create_and_return_application(user, "logo test1")

    {:ok, %{inserted_application: _other_app, inserted_env: other_env}} =
      create_and_return_application(user, "logo test2")

    {:ok,
     app: app,
     env: env,
     other_env: other_env,
     png_image: %{
       data: File.read!(Application.app_dir(:identity_web, "/priv/static/images/appicon.png")),
       type: "image/png"
     },
     svg_image: %{
       data: File.read!(Application.app_dir(:identity_web, "/priv/static/images/logo.svg")),
       type: "image/svg+xml"
     }}
  end

  defp create_and_return_application(user, name) do
    Apps.create_app(user.id, %{
      name: name,
      color: "FFFFFF",
      icon: "60189"
    })
  end

  describe "put app logo" do
    test "not existing", %{app: app, png_image: png_image} do
      assert {:ok, %{inserted_image: image, new_logo: logo}} =
               Apps.set_logo(app.creator_id, %{
                 "app_id" => app.id,
                 "data" => png_image.data,
                 "type" => png_image.type
               })

      assert image.creator_id == app.creator_id
      assert image.type == png_image.type
      assert image.data == png_image.data

      assert logo.application_id == app.id
      assert logo.environment_id == nil
      assert logo.image_id == image.id
    end

    test "existing", %{
      app: app,
      png_image: png_image,
      svg_image: svg_image
    } do
      assert {:ok, %{inserted_image: initial_image, old_logo: initial_old_logo, new_logo: initial_logo}} =
               Apps.set_logo(app.creator_id, %{
                 "app_id" => app.id,
                 "data" => png_image.data,
                 "type" => png_image.type
               })

      assert is_nil(initial_old_logo)

      png_image_id = initial_image.id
      png_logo_id = initial_logo.id

      assert initial_image.type == png_image.type
      assert initial_logo.image_id == initial_image.id

      assert {:ok, %{inserted_image: image, old_logo: old_logo, new_logo: logo}} =
               Apps.set_logo(app.creator_id, %{
                 "app_id" => app.id,
                 "data" => svg_image.data,
                 "type" => svg_image.type
               })

      assert !is_nil(old_logo)

      assert image.type == svg_image.type
      assert logo.image_id == image.id
      assert image.id != png_image_id, "image id should be different"
      assert old_logo.id == png_logo_id, "logo id should be the same"
      assert logo.id == png_logo_id, "logo id should be the same"
    end

    test "existing and reused image", %{
      app: app,
      env: env,
      png_image: png_image,
      svg_image: svg_image
    } do
      assert {:ok, %{inserted_image: initial_image, old_logo: _initial_old_logo, new_logo: initial_logo}} =
               Apps.set_logo(app.creator_id, %{
                 "app_id" => app.id,
                 "data" => png_image.data,
                 "type" => png_image.type
               })

      assert {:ok, new_logo} = Repo.insert(Logo.new(app.id, env.id, %{image_id: initial_image.id}))

      assert initial_image.type == png_image.type
      assert initial_logo.image_id == initial_image.id
      assert new_logo.image_id == initial_image.id

      assert {:ok, %{inserted_image: image, old_logo: old_logo, new_logo: logo}} =
               Apps.set_logo(app.creator_id, %{
                 "app_id" => app.id,
                 "data" => svg_image.data,
                 "type" => svg_image.type
               })

      assert image.type == svg_image.type
      assert logo.image_id == image.id
      assert image.id != initial_image.id, "image id should be different"
      assert old_logo.id == logo.id, "logo id should be the same"
      assert initial_logo.id == logo.id, "logo id should be the same"
    end
  end

  describe "put env logo" do
    test "not existing", %{app: app, env: env, png_image: png_image} do
      assert {:ok, %{inserted_image: initial_image, old_logo: _initial_old_logo, new_logo: initial_logo}} =
               Apps.set_logo(app.creator_id, %{
                 "app_id" => app.id,
                 "env_id" => env.id,
                 "data" => png_image.data,
                 "type" => png_image.type
               })

      assert initial_image.creator_id == app.creator_id
      assert initial_image.type == png_image.type
      assert initial_image.data == png_image.data

      assert initial_logo.application_id == app.id
      assert initial_logo.environment_id == env.id
      assert initial_logo.image_id == initial_image.id
    end

    test "existing", %{
      app: app,
      env: env,
      png_image: png_image,
      svg_image: svg_image
    } do
      assert {:ok, %{inserted_image: initial_image, old_logo: initial_old_logo, new_logo: initial_logo}} =
               Apps.set_logo(app.creator_id, %{
                 "app_id" => app.id,
                 "env_id" => env.id,
                 "data" => png_image.data,
                 "type" => png_image.type
               })

      assert is_nil(initial_old_logo)

      png_image_id = initial_image.id
      png_logo_id = initial_logo.id

      assert initial_image.type == png_image.type
      assert initial_logo.image_id == initial_image.id

      assert {:ok, %{inserted_image: image, old_logo: old_logo, new_logo: logo}} =
               Apps.set_logo(app.creator_id, %{
                 "app_id" => app.id,
                 "env_id" => env.id,
                 "data" => svg_image.data,
                 "type" => svg_image.type
               })

      assert !is_nil(old_logo)

      assert image.type == svg_image.type
      assert logo.image_id == image.id
      assert image.id != png_image_id, "image id should be different"
      assert old_logo.id == png_logo_id, "logo id should be the same"
      assert logo.id == png_logo_id, "logo id should be the same"
    end

    test "existing and reused image", %{
      app: app,
      env: env,
      other_env: other_env,
      png_image: png_image,
      svg_image: svg_image
    } do
      assert {:ok, %{inserted_image: initial_image, old_logo: _initial_old_logo, new_logo: initial_logo}} =
               Apps.set_logo(app.creator_id, %{
                 "app_id" => app.id,
                 "env_id" => env.id,
                 "data" => png_image.data,
                 "type" => png_image.type
               })

      assert {:ok, new_logo} = Repo.insert(Logo.new(app.id, other_env.id, %{image_id: initial_image.id}))

      assert initial_image.type == png_image.type
      assert initial_logo.image_id == initial_image.id
      assert new_logo.image_id == initial_image.id

      assert {:ok, %{inserted_image: image, old_logo: old_logo, new_logo: logo}} =
               Apps.set_logo(app.creator_id, %{
                 "app_id" => app.id,
                 "env_id" => env.id,
                 "data" => svg_image.data,
                 "type" => svg_image.type
               })

      assert image.type == svg_image.type
      assert logo.image_id == image.id
      assert image.id != initial_image.id, "image id should be different"
      assert old_logo.id == logo.id, "logo id should be the same"
      assert initial_logo.id == logo.id, "logo id should be the same"
    end
  end
end
