defmodule LenraWeb.ErrorView do
  use LenraWeb, :view
  require Logger

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  def render("500.json", _assigns) do
    %{"error" => "Internal Server Error"}
  end

  def render("404.json", _assigns) do
    %{"error" => "Page not found"}
  end

  def render("401.json", %{message: message}) do
    %{"error" => message}
  end

  def render("401.json", _assigns) do
    %{"error" => "Unauthorized"}
  end

  def render("403.json", _assigns) do
    %{"error" => "Forbidden"}
  end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def template_not_found(_template, assigns) do
    Logger.debug("ERROR VIEW NOT FOUND")
    render("500.json", assigns)
  end
end
