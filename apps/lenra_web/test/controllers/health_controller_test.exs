defmodule LenraWeb.HealthControllerTest do
  @moduledoc """
    Test the `LenraWeb.HealthControllerTest` module
  """
  use LenraWeb.ConnCase, async: true

  describe "index" do
    test "Health check", %{conn: conn} do
      conn = get(conn, Routes.health_path(conn, :index))
      assert response(conn, 200) =~ ""
    end
  end
end
