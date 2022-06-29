defmodule Lenra.Apps.BuildTest do
  @moduledoc """
    Test the build services
  """
  use Lenra.RepoCase, async: true

  alias Lenra.{
    GitlabStubHelper,
    Repo
  }

  alias Lenra.Apps
  alias Lenra.Apps.{App, Build}

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

  describe "get" do
    test "not existing build", %{app: _app} do
      assert nil == Repo.get(Build, 0)
    end

    test "existing build", %{app: app} do
      Apps.create_build_and_trigger_pipeline(app.creator_id, app.id, %{
        commit_hash: "abcdef"
      })

      build = Enum.at(Repo.all(Build), 0)

      assert %Build{commit_hash: "abcdef", status: :pending} = Repo.get(Build, build.id)
    end
  end

  describe("get by") do
    test "build_number", %{app: app} do
      Apps.create_build_and_trigger_pipeline(app.creator_id, app.id, %{
        commit_hash: "abcdef"
      })

      assert {:ok, %Build{commit_hash: "abcdef", status: :pending}} = Repo.fetch_by(Build, %{build_number: 1})
    end
  end

  describe "create" do
    test "build but invalid params", %{app: app} do
      assert {:error, :inserted_build, _failed_value, _changes_so_far} =
               Apps.create_build_and_trigger_pipeline(app.creator_id, app.id, %{
                 commit_hash: 12
               })
    end

    test "build successfully", %{app: app} do
      Apps.create_build_and_trigger_pipeline(app.creator_id, app.id, %{
        commit_hash: "abcdef"
      })

      build = Enum.at(Repo.all(Build), 0)

      assert %Build{commit_hash: "abcdef", status: :pending} = build
    end
  end

  describe "update" do
    test "build successfully", %{app: app} do
      {:ok, %{inserted_build: build}} =
        Apps.create_build_and_trigger_pipeline(app.creator_id, app.id, %{
          commit_hash: "abcdef"
        })

      Apps.update_build(build, %{status: :success})

      updated_build = Enum.at(Repo.all(Build), 0)

      assert updated_build.status == :success
    end
  end
end
