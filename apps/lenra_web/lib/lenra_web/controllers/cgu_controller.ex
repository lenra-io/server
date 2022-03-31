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

  def get_latest_cgu_as_html(conn, _params) do
    with {:ok, _cgu} <- CguService.get_latest_cgu() do
      conn
      |> html(File.read!("apps/lenra_web/priv/static/cgu/CGU.html"))
      |> reply
    end
  end
end
