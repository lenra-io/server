defmodule Lenra.Apps.LogoTest do
  @moduledoc """
    Test the logo services
  """
  use Lenra.RepoCase, async: true

  alias Lenra.{
    FaasStub,
    GitlabStubHelper,
    Repo
  }

  alias Lenra.Apps
  alias Lenra.Apps.{App, Image, Logo, Environment}

  setup do
    {:ok,
     app: create_and_return_application(),
     image_data: File.read!(Application.app_dir(:identity_web, "/priv/static/images/appicon.png")),
     image_type: "image/png"}
  end

  defp create_and_return_application do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    Apps.create_app(user.id, %{
      name: "mine-sweeper",
      color: "FFFFFF",
      icon: "60189"
    })

    Enum.at(Repo.all(App), 0)
  end

  describe "put" do
    test "not existing app logo", %{app: app, image_data: image_data, image_type: image_type} do
      Apps.set_logo(app.creator_id, %{
        "app_id" => app.id,
        "env_id" => nil,
        "data" => image_data,
        "type" => image_type
      })

      image = Enum.at(Repo.all(Image), 0)
      logo = Enum.at(Repo.all(Logo), 0)

      assert %Image{
              #  creator_id: app.creator.id,
               type: image_type,
               data: image_data
             } = image

      assert %Logo{
               # application_id: app.id,
               # environment_id: nil,
               # image_id: image.id
             } = logo
    end

    # test "existing", %{app: app} do
    #   Apps.create_build_and_deploy(app.creator_id, app.id, %{
    #     commit_hash: "abcdef"
    #   })

    #   build = Enum.at(Repo.all(Build), 0)

    #   assert %Build{commit_hash: "abcdef", status: :pending} = build
    # end
  end
end
