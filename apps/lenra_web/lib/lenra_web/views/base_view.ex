defmodule LenraWeb.BaseView do
  use LenraWeb, :view
  require Logger

  # def render("success.json", %{}) do
  #   %{"ok" => "200"}
  # end

  def render("success.json", %{data: data}) do
    %{
      "data" => data
    }
  end

  def render("success.json", _no_data) do
    %{}
  end

  def render("error.json", %{error: error}) do
    %{"error" => translate_error(error)}
  end
end
