defmodule LenraWeb.ErrorViewTest do
  @moduledoc """
    Test the Errors for some routes
  """
  use LenraWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  alias Lenra.Errors.TechnicalError

  test "renders 404.json" do
    assert render(LenraWeb.ErrorView, "404.json", Map.to_list(TechnicalError.error_404())) ==
             %{
               "message" => "Not Found.",
               "reason" => :error_404
             }
  end

  test "renders 500.json" do
    assert render(LenraWeb.ErrorView, "500.json", Map.to_list(TechnicalError.error_500())) ==
             %{"message" => "Internal server error.", "reason" => :error_500}
  end
end
