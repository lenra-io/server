defmodule Lenra.ApplicationServicesTest do
  @moduledoc """
    Test the application services
  """

  use Lenra.RepoCase, async: true

  alias Lenra.LenraApplicationServices

  @tag :register_user
  test "fetch app", %{user: user} do
    params = %{
      name: "mine-sweeper",
      color: "FFFFFF",
      icon: "60189"
    }

    case LenraApplicationServices.create(user.id, params) do
      {:ok, %{inserted_application: app}} ->
        assert {:ok, _app} = LenraApplicationServices.fetch(app.id)

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

    case LenraApplicationServices.create(user.id, params) do
      {:ok, %{inserted_application: app}} ->
        assert {:ok, _value} = LenraApplicationServices.fetch_by(name: app.name)

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

    {:ok, %{inserted_application: app}} = LenraApplicationServices.create(user.id, params)

    assert {:ok, _app} = LenraApplicationServices.fetch_by(name: "mine-sweeper")

    LenraApplicationServices.delete(app)

    assert {:error, :error_404} == LenraApplicationServices.fetch_by(name: "mine-sweeper")
  end
end
