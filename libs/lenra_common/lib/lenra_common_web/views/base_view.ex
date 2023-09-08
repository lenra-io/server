defmodule LenraCommonWeb.BaseView do
  use LenraCommonWeb, :view
  require Logger

  def render("success.json", %{data: data}) do
    %{
      "data" => data
    }
  end

  def render("success.json", %{root: data}) do
    data
  end

  def render("success.json", _no_data) do
    %{}
  end

  def render("error.json", %{error: error}) do
    translate_error(error)
  end
end
