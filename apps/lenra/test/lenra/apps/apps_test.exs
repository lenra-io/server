defmodule Lenra.Apps.AppsTest do
  @moduledoc """
    Test the application services
  """

  use Lenra.RepoCase, async: true

  alias Lenra.Apps

  @tag :register_user
  test "fetch_app", %{user: user} do
    params = %{
      name: "mine-sweeper",
      color: "FFFFFF",
      icon: "60189"
    }

    case Apps.create_app(user.id, params) do
      {:ok, %{inserted_application: app}} ->
        assert {:ok, _app} = Apps.fetch_app(app.id)

      {:error, _} ->
        assert false, "adding app failed"
    end
  end

  @tag :register_user
  test "fetch app by", %{user: user} do
    params = %{
      name: "mine-sweeper",
      color: "FFFFFF",
      icon: "60189"
    }

    case Apps.create_app(user.id, params) do
      {:ok, %{inserted_application: app}} ->
        assert {:ok, _value} = Apps.fetch_app_by(name: app.name)

      {:error, _} ->
        assert false, "adding app failed"
    end
  end

  @tag :register_user
  test "delete app", %{user: user} do
    params = %{
      name: "mine-sweeper",
      color: "FFFFFF",
      icon: "60189"
    }

    {:ok, %{inserted_application: app}} = Apps.create_app(user.id, params)

    assert {:ok, _app} = Apps.fetch_app_by(name: "mine-sweeper")

    Apps.delete_app(app)

    assert {:error, Lenra.Errors.error_404()} == Apps.fetch_app_by(name: "mine-sweeper")
  end
end