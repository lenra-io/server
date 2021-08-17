defmodule LenraWeb.TokenHelper do
  @moduledoc """
    The TokenService module handle the refresh_token and access_token operations
  """

  @token_key "guardian_default_token"

  alias Lenra.Guardian.{ErrorHandler, Plug}

  def assign_access_and_refresh_token(conn, user) do
    conn = create_refresh_and_store_cookie(conn, user)

    with {:ok, refresh_token} <- get_cookie_from_resp(conn),
         access_token <- create_access_token(refresh_token) do
      assign_access_token(conn, access_token)
    else
      error ->
        ErrorHandler.auth_error(conn, error, [])
    end
  end

  def get_cookie_from_resp(conn) do
    case conn.resp_cookies do
      %{@token_key => %{value: token}} -> {:ok, token}
      _ -> {:unauthenticated, :no_token_found}
    end
  end

  def assign_access_token(conn, access_token) do
    LenraWeb.ControllerHelpers.assign_data(conn, :access_token, access_token)
  end

  def create_refresh_and_store_cookie(conn, user) do
    Plug.remember_me(conn, user, %{typ: "refresh"})
  end

  def create_access_token(refresh_token) do
    {:ok, _, {access_token, _new_claims}} = Lenra.Guardian.exchange(refresh_token, "refresh", "access")

    access_token
  end

  def revoke_current_refresh(conn) do
    refresh_token = Plug.current_token(conn)
    Lenra.Guardian.revoke(refresh_token)
    conn
  end
end
