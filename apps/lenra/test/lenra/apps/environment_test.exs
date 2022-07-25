defmodule Lenra.Apps.EnvironmentTest do
  @moduledoc """
    Test the environment services
  """
  use Lenra.RepoCase, async: true

  alias Lenra.Repo

  alias Lenra.Errors.TechnicalError

  alias Lenra.Accounts.User
  alias Lenra.Apps
  alias Lenra.Apps.{App, Environment}

  setup do
    {:ok, app: create_and_return_application()}
  end

  defp fetch_env_by(clauses) do
    Repo.fetch_by(Environment, clauses)
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

  describe "get_env" do
    test "not existing environment", %{app: _app} do
      assert nil == Apps.get_env(0)
    end

    test "existing environment", %{app: _app} do
      {:ok, env} = Enum.fetch(Repo.all(Environment), 0)

      assert nil != Apps.get_env(env.id)
    end
  end

  describe "fetch by" do
    test "name", %{app: _app} do
      assert {:ok, _env} = fetch_env_by(name: "live")
    end

    test "ephemeral", %{app: _app} do
      assert {:ok, _env} = fetch_env_by(is_ephemeral: false)
    end
  end

  describe "create" do
    test "environment successfully", %{app: app} do
      {:ok, user} = Enum.fetch(Repo.all(User), 0)

      Apps.create_env(app.id, user.id, %{
        name: "test_env",
        is_ephemeral: false,
        is_public: false
      })

      assert 2 == Enum.count(Repo.all(Environment))
    end

    test "environment but invalid params", %{app: app} do
      {:ok, user} = Enum.fetch(Repo.all(User), 0)

      error =
        Apps.create_env(app.id, user.id, %{
          name: 1234,
          is_ephemeral: "yes",
          is_public: false
        })

      assert {:error, :inserted_env, _failed_value, _changes_so_far} = error
    end
  end

  describe "update" do
    test "environment successfully", %{app: app} do
      {:ok, user} = Enum.fetch(Repo.all(User), 0)

      Apps.create_env(app.id, user.id, %{
        name: "test_env",
        is_ephemeral: false,
        is_public: false
      })

      {:ok, env} = fetch_env_by(name: "test_env")

      assert env.is_public == false

      Apps.update_env(env, %{
        is_public: true
      })

      {:ok, updated_env} = fetch_env_by(name: "test_env")

      assert updated_env.is_public == true
    end
  end

  describe "delete" do
    test "environment successfully", %{app: _app} do
      assert {:ok, env} = fetch_env_by(name: "live")

      env
      |> Repo.delete!()

      assert TechnicalError.error_404_tuple() == fetch_env_by(name: "live")
    end
  end
end
