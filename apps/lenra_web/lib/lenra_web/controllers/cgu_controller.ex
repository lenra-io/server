defmodule LenraWeb.CguController do
  use LenraWeb, :controller

  alias Lenra.Legal

  def get_latest_cgu(conn, _params) do
    with {:ok, cgu} <- Legal.get_latest_cgu() do
      conn
      |> reply(cgu)
    end
  end

  def accept(conn, %{"cgu_id" => cgu_id} = _params) do
    user_id = Guardian.Plug.current_resource(conn).id

    with {:ok, %{accepted_cgu: cgu}} <- Legal.accept_cgu(cgu_id, user_id) do
      conn
      |> reply(cgu)
    end
  end

  def user_accepted_latest_cgu(conn, _params) do
    user_id = Guardian.Plug.current_resource(conn).id

    conn
    |> reply(Legal.user_accepted_latest_cgu?(user_id))
  end
end
