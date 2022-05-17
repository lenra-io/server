defmodule Lenra.RepositoryTest do
  use Lenra.RepoCase, async: true

  alias Lenra.Repository

  @valid_repository %{url: "http://git.com/git.git", branch: "master", username: "admin", token: "password"}
  @valid_repository_nil_values %{url: "http://git.com/git.git", branch: nil, username: nil, token: nil}
  @invalid_repository %{url: nil, branch: 123, username: 123, token: 123}

  describe "lenra_repository" do
    test "new/2 with valid data creates a repository" do
      assert %{changes: repository, valid?: true} = Repository.new(1, @valid_repository)
      assert repository.url == @valid_repository.url
      assert repository.branch == @valid_repository.branch
      assert repository.username == @valid_repository.username
      assert repository.token == @valid_repository.token
    end

    test "new/2 with invalid data creates an invalid repository" do
      assert %{changes: _repository, valid?: false} = Repository.new(1, @invalid_repository)
    end

    test "inserting a valid repository should succeed" do
      {:ok, inserted_user} = Repo.insert(Lenra.User.new(%{email: "fake@user.com"}, :user))

      {:ok, inserted_app} = Repo.insert(
        Lenra.LenraApplication.new(inserted_user.id, %{
          name: "fakeapp",
          service_name: "fakeservice",
          color: "FF0000",
          icon: 12
        })
      )

      repository = Repository.new(inserted_app.id, @valid_repository)
      {:ok, %Repository{} = inserted_repository} = Repo.insert(repository)

      assert %{valid?: true} = repository

      [head | _tail] = Repo.all(from(Repository))
      assert head == inserted_repository
    end

    test "inserting an invalid repository should not succeed" do
      repository = Repository.new(1, @invalid_repository)

      assert {:error,
              %{
                errors: [
                  url: {"can't be blank", _},
                  branch: {"is invalid", _},
                  username: {"is invalid", _},
                  token: {"is invalid", _}
                ]
              }} = Repo.insert(repository)
    end
  end
end
