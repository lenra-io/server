defmodule LenraWeb.ErrorViewTest do
  @moduledoc """
    Test the Errors for some routes
  """
  use LenraWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.json" do
    assert render(LenraWeb.ErrorView, "404.json", []) == %{
             "errors" => [%{code: 404, message: "Page not found"}],
             "success" => false
           }
  end

  test "renders 500.json" do
    assert render(LenraWeb.ErrorView, "500.json", []) ==
             %{"errors" => [%{code: 500, message: "Internal Server Error"}], "success" => false}
  end
end
