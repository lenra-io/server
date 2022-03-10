defmodule LenraWeb.CguController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.CguController.Policy

  alias Lenra.CguService

  def get_latest_cgu(conn, _params) do
    cgu = CguService.get_latest_cgu()

    conn
    |> assign_data(:latest_cgu, cgu)
    |> reply
  end
end
