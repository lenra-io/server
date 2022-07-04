defmodule LenraWeb.ErrorViewTest do
  @moduledoc """
    Test the Errors for some routes
  """
  use LenraWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.json" do
    assert render(LenraWeb.ErrorView, "404.json", []) == %{
             "error" => "Page not found"
           }
  end

  test "renders 500.json" do
    assert render(LenraWeb.ErrorView, "500.json", []) ==
             %{"error" => "Internal Server Error"}
  end
end
