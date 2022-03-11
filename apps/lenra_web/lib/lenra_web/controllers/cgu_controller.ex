defmodule LenraWeb.CguController do
  use LenraWeb, :controller

  alias Lenra.CguService

  def get_latest_cgu(conn, _params) do
    with {:ok, cgu} <- CguService.get_latest_cgu() do
      conn
      |> assign_data(:latest_cgu, cgu)
      |> reply
    end
  end
end
