defmodule Lenra.BuildServicesTest do
  @moduledoc """
    Test the build services
  """
  use Lenra.RepoCase, async: true

  alias Lenra.{
    ApplicationMainEnvServices,
    Build,
    BuildServices,
    GitlabStubHelper,
    LenraApplication,
    LenraApplicationServices,
    Repo
  }

  setup do
    GitlabStubHelper.create_gitlab_stub()

    {:ok, app: create_and_return_application()}
  end

  defp create_and_return_application do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    LenraApplicationServices.create(user.id, %{
      name: "mine-sweeper",
      color: "FFFFFF",
      icon: "60189"
    })

    Enum.at(Repo.all(LenraApplication), 0)
  end

  describe "get" do
    test "application main env successfully", %{app: app} do
      main_env = ApplicationMainEnvServices.get(app.id)
      assert nil != main_env
      assert main_env.application_id == app.id
    end
  end
end
