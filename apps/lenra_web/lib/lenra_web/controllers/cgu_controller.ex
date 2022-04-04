defmodule LenraWeb.CguController do
  use LenraWeb, :controller

  alias Lenra.CguService

  def get_latest_cgu(conn, _params) do
    with {:ok, cgu} <- CguServices.get_latest_cgu() do
      conn
      |> assign_data(:latest_cgu, cgu)
      |> reply
    end
  end

  def accept_cgu(conn, %{cgu_id: cgu_id, user_id: user_id} = _params) do
    with {:ok, cgu} <- CguServices.accept_cgu(cgu_id, user_id) do
      conn
      |> assign_data(:accepted_cgu, cgu)
      |> reply
    end
  end
end
