defmodule Lenra.BuildServicesTest do
  @moduledoc """
    Test the build services
  """
  use Lenra.RepoCase, async: true

  alias Lenra.{
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
    test "not existing build", %{app: _app} do
      assert nil == BuildServices.get(0)
    end

    test "existing build", %{app: app} do
      BuildServices.create_and_trigger_pipeline(app.creator_id, app.id, %{
        commit_hash: "abcdef"
      })

      build = Enum.at(Repo.all(Build), 0)

      assert %Build{commit_hash: "abcdef", status: :pending} = BuildServices.get(build.id)
    end
  end

  describe("get by") do
    test "build_number", %{app: app} do
      BuildServices.create_and_trigger_pipeline(app.creator_id, app.id, %{
        commit_hash: "abcdef"
      })

      assert {:ok, %Build{commit_hash: "abcdef", status: :pending}} = BuildServices.fetch_by(%{build_number: 1})
    end
  end

  describe "create" do
    test "build but invalid params", %{app: app} do
      assert {:error, :inserted_build, _, _} =
               BuildServices.create_and_trigger_pipeline(app.creator_id, app.id, %{
                 commit_hash: 12
               })
    end

    test "build successfully", %{app: app} do
      BuildServices.create_and_trigger_pipeline(app.creator_id, app.id, %{
        commit_hash: "abcdef"
      })

      build = Enum.at(Repo.all(Build), 0)

      assert %Build{commit_hash: "abcdef", status: :pending} = build
    end
  end

  describe "update" do
    test "build successfully", %{app: app} do
      {:ok, %{inserted_build: build}} =
        BuildServices.create_and_trigger_pipeline(app.creator_id, app.id, %{
          commit_hash: "abcdef"
        })

      BuildServices.update(build, %{status: :success})

      updated_build = Enum.at(Repo.all(Build), 0)

      assert updated_build.status == :success
    end
  end

  describe "delete" do
    test "build successfully", %{app: app} do
      BuildServices.create_and_trigger_pipeline(app.creator_id, app.id, %{
        commit_hash: "abcdef"
      })

      assert [] != Repo.all(Build)
      build = Enum.at(Repo.all(Build), 0)

      build
      |> BuildServices.delete()
      |> Repo.transaction()

      assert [] == Repo.all(Build)
    end
  end
end
