defmodule LenraWeb.CgsController do
  use LenraWeb, :controller

  alias Lenra.Legal

  def get_latest_cgs(conn, _params) do
    with {:ok, cgs} <- Legal.get_latest_cgs() do
      conn
      |> reply(cgs)
    end
  end

  def accept(conn, %{"cgs_id" => cgs_id} = _params) do
    user_id = LenraWeb.Auth.current_resource(conn).id

    with {:ok, %{accepted_cgs: cgs}} <- Legal.accept_cgs(cgs_id, user_id) do
      conn
      |> reply(cgs)
    end
  end

  def user_accepted_latest_cgs(conn, _params) do
    user_id = LenraWeb.Auth.current_resource(conn).id

    conn
    |> reply(%{accepted: Legal.user_accepted_latest_cgs?(user_id)})
  end
end
