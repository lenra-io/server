defmodule Lenra.Apps.LogoTest do
  @moduledoc """
    Test the logo services
  """
  use Lenra.RepoCase, async: true

  alias Lenra.Apps
  alias Lenra.Apps.{App, Image, Logo}
  alias Lenra.Repo

  setup do
    {:ok, %{inserted_application: app, inserted_env: env}} = create_and_return_application()

    {:ok,
     app: app,
     env: env,
     png_image: %{
       data: File.read!(Application.app_dir(:identity_web, "/priv/static/images/appicon.png")),
       type: "image/png"
     },
     svg_image: %{
       data: File.read!(Application.app_dir(:identity_web, "/priv/static/images/logo.svg")),
       type: "image/svg+xml"
     }}
  end

  defp create_and_return_application do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    Apps.create_app(user.id, %{
      name: "mine-sweeper",
      color: "FFFFFF",
      icon: "60189"
    })
  end

  describe "put app logo" do
    test "not existing", %{app: app, png_image: png_image} do
      Apps.set_logo(app.creator_id, %{
        "app_id" => app.id,
        "env_id" => nil,
        "data" => png_image.data,
        "type" => png_image.type
      })

      images = Repo.all(Image)
      logos = Repo.all(Logo)

      assert length(images) == 1
      assert length(logos) == 1

      image = Enum.at(images, 0)
      logo = Enum.at(logos, 0)

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
      Apps.set_logo(app.creator_id, %{
        "app_id" => app.id,
        "env_id" => nil,
        "data" => png_image.data,
        "type" => png_image.type
      })

      images = Repo.all(Image)
      logos = Repo.all(Logo)
      assert length(images) == 1
      assert length(logos) == 1
      image = Enum.at(images, 0)
      logo = Enum.at(logos, 0)

      png_image_id = image.id

      assert image.type == png_image.type
      assert logo.image_id == image.id

      Apps.set_logo(app.creator_id, %{
        "app_id" => app.id,
        "env_id" => nil,
        "data" => svg_image.data,
        "type" => svg_image.type
      })

      images = Repo.all(Image)
      logos = Repo.all(Logo)
      assert length(images) == 1
      assert length(logos) == 1
      image = Enum.at(images, 0)
      logo = Enum.at(logos, 0)

      assert image.type == svg_image.type
      assert logo.image_id == image.id
      assert image.id != png_image_id, "image id should be different"
    end

    test "existing and reused image", %{
      app: app,
      env: env,
      png_image: png_image,
      svg_image: svg_image
    } do
      Apps.set_logo(app.creator_id, %{
        "app_id" => app.id,
        "env_id" => nil,
        "data" => png_image.data,
        "type" => png_image.type
      })

      images = Repo.all(Image)
      logos = Repo.all(Logo)
      assert length(images) == 1
      assert length(logos) == 1
      image = Enum.at(images, 0)
      logo = Enum.at(logos, 0)

      Repo.insert(Logo.new(app.id, env.id, %{image_id: image.id}))

      png_image_id = image.id

      assert image.type == png_image.type
      assert logo.image_id == image.id

      Apps.set_logo(app.creator_id, %{
        "app_id" => app.id,
        "env_id" => nil,
        "data" => svg_image.data,
        "type" => svg_image.type
      })

      images = Repo.all(Image)
      logos = Repo.all(Logo)
      assert length(images) == 2
      assert length(logos) == 2
      logo = Repo.one(from(l in Logo, where: l.application_id == ^app.id and is_nil(l.environment_id)))
      image_id = logo.image_id
      image = Repo.one(from(i in Image, where: i.id == ^image_id))

      assert image.type == svg_image.type
      assert logo.image_id == image.id
      assert image.id != png_image_id, "image id should be different"
    end
  end

  describe "put env logo" do
    test "not existing", %{app: app, env: env, png_image: png_image} do
      Apps.set_logo(app.creator_id, %{
        "app_id" => app.id,
        "env_id" => env.id,
        "data" => png_image.data,
        "type" => png_image.type
      })

      images = Repo.all(Image)
      logos = Repo.all(Logo)

      assert length(images) == 1
      assert length(logos) == 1

      image = Enum.at(images, 0)
      logo = Enum.at(logos, 0)

      assert image.creator_id == app.creator_id
      assert image.type == png_image.type
      assert image.data == png_image.data

      assert logo.application_id == app.id
      assert logo.environment_id == env.id
      assert logo.image_id == image.id
    end

    test "existing", %{
      app: app,
      env: env,
      png_image: png_image,
      svg_image: svg_image
    } do
      Apps.set_logo(app.creator_id, %{
        "app_id" => app.id,
        "env_id" => env.id,
        "data" => png_image.data,
        "type" => png_image.type
      })

      images = Repo.all(Image)
      logos = Repo.all(Logo)
      assert length(images) == 1
      assert length(logos) == 1
      image = Enum.at(images, 0)
      logo = Enum.at(logos, 0)

      png_image_id = image.id

      assert image.type == png_image.type
      assert logo.image_id == image.id

      Apps.set_logo(app.creator_id, %{
        "app_id" => app.id,
        "env_id" => env.id,
        "data" => svg_image.data,
        "type" => svg_image.type
      })

      images = Repo.all(Image)
      logos = Repo.all(Logo)
      assert length(images) == 1
      assert length(logos) == 1
      image = Enum.at(images, 0)
      logo = Enum.at(logos, 0)

      assert image.type == svg_image.type
      assert logo.image_id == image.id
      assert image.id != png_image_id, "image id should be different"
    end

    test "existing and reused image", %{
      app: app,
      env: env,
      png_image: png_image,
      svg_image: svg_image
    } do
      Apps.set_logo(app.creator_id, %{
        "app_id" => app.id,
        "env_id" => env.id,
        "data" => png_image.data,
        "type" => png_image.type
      })

      images = Repo.all(Image)
      logos = Repo.all(Logo)
      assert length(images) == 1
      assert length(logos) == 1
      image = Enum.at(images, 0)
      logo = Enum.at(logos, 0)

      Repo.insert(Logo.new(app.id, nil, %{image_id: image.id}))

      png_image_id = image.id

      assert image.type == png_image.type
      assert logo.image_id == image.id

      Apps.set_logo(app.creator_id, %{
        "app_id" => app.id,
        "env_id" => env.id,
        "data" => svg_image.data,
        "type" => svg_image.type
      })

      images = Repo.all(Image)
      logos = Repo.all(Logo)
      assert length(images) == 2
      assert length(logos) == 2
      logo = Repo.one(from(l in Logo, where: l.application_id == ^app.id and l.environment_id == ^env.id))
      image_id = logo.image_id
      image = Repo.one(from(i in Image, where: i.id == ^image_id))

      assert image.type == svg_image.type
      assert logo.image_id == image.id
      assert image.id != png_image_id, "image id should be different"
    end
  end
end
