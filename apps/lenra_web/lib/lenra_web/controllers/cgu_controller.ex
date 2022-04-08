defmodule LenraWeb.CguController do
  use LenraWeb, :controller

  alias Lenra.CguServices

  def get_latest_cgu(conn, _params) do
    with {:ok, cgu} <- CguServices.get_latest_cgu() do
      conn
      |> assign_data(:latest_cgu, cgu)
      |> reply
    end
  end

  def accept(conn, %{"user_id" => user_id, "cgu_id" => cgu_id} = _params) do
    with {:ok, %{accepted_cgu: cgu}} <- CguServices.accept(cgu_id, user_id) do
      conn
      |> assign_data(:accepted_cgu, cgu)
      |> reply
    end
  end

  def user_accepted_latest_cgu(conn, _params) do
    user_id = Guardian.Plug.current_resource(conn).id

    if CguServices.user_accepted_latest_cgu?(user_id) do
      conn
      |> assign_data(:user_accepted_latest_cgu, true)
      |> reply
    else
      {:error, :did_not_accept_cgu}
    end
  end
end
