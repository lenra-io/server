defmodule LenraWeb.DataControllerTest do
  @moduledoc """
    Test the `LenraWeb.DataController` module
  """

  use LenraWeb.ConnCase, async: true

  alias Lenra.{Environment, LenraApplication, Repo}

  setup %{conn: conn} do
    {:ok, %{conn: conn}}
  end

  defp create_app_and_get_env(conn) do
    post(conn, Routes.apps_path(conn, :create), %{
      "name" => "test",
      "color" => "ffffff",
      "icon" => 12
    })

    Repo.get_by(Environment, application_id: Enum.at(Repo.all(LenraApplication), 0).id)
  end

  # TODO make tests when route are defined
  describe "LenraWeb.DataController.create_2/1" do
    test "should create data if params valid" do
    end

    test "should return error if params not valid" do
    end
  end

  describe "LenraWeb.DataController.update_2/1" do
    test "should update data if params valid" do
    end

    test "should return error if params not valid" do
    end
  end

  describe "LenraWeb.DataController.delete_1/1" do
    test "should delete data if id valid" do
    end

    test "should return error if id invalid" do
    end
  end
end