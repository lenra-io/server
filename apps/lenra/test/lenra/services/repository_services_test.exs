defmodule Lenra.RepositoryServicesTest do
  @moduledoc """
    Test the repository services
  """
  use Lenra.RepoCase, async: true

  alias Lenra.{
    Repository,
    RepositoryServices,
    LenraApplication,
    LenraApplicationServices,
    Repo
  }

  setup do
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

  describe "fetch" do
    test "not existing repository", %{app: _app} do
      assert {:error, :error_404} == RepositoryServices.fetch(0)
    end

    test "existing repository", %{app: app} do
      RepositoryServices.create(app.id, %{
        url: "http://git.com/git.git",
        branch: "master",
        username: "admin",
        token: "password"
      })

      repository = Enum.at(Repo.all(Repository), 0)

      assert %Repository{url: "http://git.com/git.git", branch: "master", username: "admin", token: "password"} =
               repository
    end
  end

  describe("fetch by") do
    test "application_id", %{app: app} do
      RepositoryServices.create(app.id, %{
        url: "http://git.com/git.git",
        branch: "master",
        username: "admin",
        token: "password"
      })

      assert {:ok, %Repository{url: "http://git.com/git.git", branch: "master", username: "admin", token: "password"}} =
               RepositoryServices.fetch_by(%{application_id: app.id})
    end
  end

  describe "create" do
    test "repository but invalid params", %{app: app} do
      assert {:error, :inserted_repository, _failed_value, _changes_so_far} =
               RepositoryServices.create(app.id, %{
                 url: nil,
                 branch: 123,
                 username: 123,
                 token: 123
               })
    end

    test "repository successfully", %{app: app} do
      RepositoryServices.create(app.id, %{
        url: "http://git.com/git.git",
        branch: "master",
        username: "admin",
        token: "password"
      })

      repository = Enum.at(Repo.all(Repository), 0)

      assert %Repository{url: "http://git.com/git.git", branch: "master", username: "admin", token: "password"} =
               repository
    end
  end

  describe "update" do
    test "repository successfully", %{app: app} do
      {:ok, %{inserted_repository: repository}} =
        RepositoryServices.create(app.id, %{
          url: "http://git.com/git.git",
          branch: "master",
          username: "admin",
          token: "password"
        })

      RepositoryServices.update(repository, %{branch: "beta"})

      updated_repository = Enum.at(Repo.all(Repository), 0)

      assert updated_repository.branch == "beta"
    end

    test "repository with wrong param", %{app: app} do
      {:ok, %{inserted_repository: repository}} =
        RepositoryServices.create(app.id, %{
          url: "http://git.com/git.git",
          branch: "master",
          username: "admin",
          token: "password"
        })

      assert {:error, :updated_repository, %Ecto.Changeset{errors: [branch: {"is invalid", _}]}, _} =
               RepositoryServices.update(repository, %{branch: 123})

      updated_repository = Enum.at(Repo.all(Repository), 0)

      assert updated_repository.branch == "master"
    end
  end

  describe "delete" do
    test "repository successfully", %{app: app} do
      RepositoryServices.create(app.id, %{
        url: "http://git.com/git.git",
        branch: "master",
        username: "admin",
        token: "password"
      })

      assert [] != Repo.all(Repository)
      repository = Enum.at(Repo.all(Repository), 0)

      RepositoryServices.delete(repository)

      assert [] == Repo.all(Repository)
    end
  end
end
