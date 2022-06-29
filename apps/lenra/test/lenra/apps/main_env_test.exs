defmodule Lenra.Apps.MainEnvTest do
  @moduledoc """
    Test the application main env services
  """
  use Lenra.RepoCase, async: true

  alias Lenra.{
    GitlabStubHelper,
    Repo
  }

  alias Lenra.Apps
  alias Lenra.Apps.App

  setup do
    GitlabStubHelper.create_gitlab_stub()

    {:ok, app: create_and_return_application()}
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

  describe "fetch_main_env_for_app" do
    test "application main env successfully", %{app: app} do
      {:ok, main_env} = Apps.fetch_main_env_for_app(app.id)
      assert nil != main_env
      assert main_env.application_id == app.id
    end
  end
end
