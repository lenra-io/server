defmodule Lenra.ApplicationServicesTest do
  use Lenra.RepoCase, async: true

  alias Lenra.LenraApplicationServices

  @moduledoc """
    Test the application services
  """

  @tag :register_user
  test "fetch app", %{user: user} do
    params = %{
      name: "mine-sweeper",
      service_name: Ecto.UUID.generate(),
      color: "FFFFFF",
      icon: "60189"
    }

    LenraApplicationServices.create(user.id, params)
    |> case do
      {:ok, %{inserted_application: app}} -> assert {:ok, _app} = LenraApplicationServices.fetch(app.id)
      {:error, _} -> assert false, "adding app failed"
    end
  end

  @tag :register_user
  test "fetch app by", %{user: user} do
    params = %{
      name: "mine-sweeper",
      service_name: Ecto.UUID.generate(),
      color: "FFFFFF",
      icon: "60189"
    }

    LenraApplicationServices.create(user.id, params)
    |> case do
      {:ok, %{inserted_application: app}} -> assert {:ok, _value} = LenraApplicationServices.fetch_by(name: app.name)
      {:error, _} -> assert false, "adding app failed"
    end
  end

  @tag :register_user
  test "delete app", %{user: user} do
    params = %{
      name: "mine-sweeper",
      service_name: Ecto.UUID.generate(),
      color: "FFFFFF",
      icon: "60189"
    }

    {:ok, %{inserted_application: app}} = LenraApplicationServices.create(user.id, params)

    assert {:ok, _app} = LenraApplicationServices.fetch_by(name: "mine-sweeper")

    LenraApplicationServices.delete(app)

    assert {:error, :error_404} == LenraApplicationServices.fetch_by(name: "mine-sweeper")
  end
end
