defmodule LenraWeb.DatastoreControllerTest do
  @moduledoc """
    Test the `LenraWeb.DatastoreController` module
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
  describe "LenraWeb.DatastoreController.create_2/1" do
    test "should create datastore if params valid" do
    end

    test "should return error if params not valid" do
    end
  end

  describe "LenraWeb.DatastoreController.update_2/1" do
    test "should update datastore if params valid" do
    end

    test "should return error if params not valid" do
    end
  end

  describe "LenraWeb.DatastoreController.delete_1/1" do
    test "should delete datastore if id valid" do
    end

    test "should return error if id invalid" do
    end
  end
end
