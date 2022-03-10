defmodule LenraWeb.CguController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.CguController.Policy

  alias Lenra.CguService

  def get_latest_cgu(conn) do
    with {:ok, %{latest_cgu: cgu}} <- CguService.get_latest_cgu() do
      conn
      |> assign_data(:latest_cgu, cgu)
      |> reply
    end
  end
end
