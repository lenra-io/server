defmodule Lenra.EnvironmentServicesTest do
  @moduledoc """
    Test the environment services
  """
  use Lenra.RepoCase, async: true

  alias Lenra.{
    Environment,
    EnvironmentServices,
    LenraApplication,
    LenraApplicationServices,
    Repo,
    User
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

  describe "get" do
    test "not existing environment", %{app: _app} do
      assert nil == EnvironmentServices.get(0)
    end

    test "existing environment", %{app: _app} do
      {:ok, env} = Enum.fetch(Repo.all(Environment), 0)

      assert nil != EnvironmentServices.get(env.id)
    end
  end

  describe "fetch by" do
    test "name", %{app: _app} do
      assert {:ok, _env} = EnvironmentServices.fetch_by(name: "live")
    end

    test "ephemeral", %{app: _app} do
      assert {:ok, _env} = EnvironmentServices.fetch_by(is_ephemeral: false)
    end
  end

  describe "create" do
    test "environment successfully", %{app: app} do
      {:ok, user} = Enum.fetch(Repo.all(User), 0)

      EnvironmentServices.create(app.id, user.id, %{
        name: "test_env",
        is_ephemeral: false,
        is_public: false
      })

      assert 2 == Enum.count(Repo.all(Environment))
    end

    test "environment but invalid params", %{app: app} do
      {:ok, user} = Enum.fetch(Repo.all(User), 0)

      error =
        EnvironmentServices.create(app.id, user.id, %{
          name: 1234,
          is_ephemeral: "yes",
          is_public: false
        })

      assert {:error, :inserted_env, _failed_value, _changes_so_far} = error
    end
  end

  describe "delete" do
    test "environment successfully", %{app: _app} do
      assert {:ok, env} = EnvironmentServices.fetch_by(name: "live")

      env
      |> EnvironmentServices.delete()
      |> Repo.transaction()

      assert {:error, :error_404} == EnvironmentServices.fetch_by(name: "live")
    end
  end
end
