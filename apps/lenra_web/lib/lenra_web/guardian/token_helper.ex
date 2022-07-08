defmodule LenraWeb.TokenHelper do
  @moduledoc """
    The TokenService module handle the refresh_token and access_token operations
  """
  alias LenraWeb.Guardian
  alias LenraWeb.Guardian.ErrorHandler

  @token_key "guardian_default_token"

  def assign_access_and_refresh_token(conn, user) do
    conn = create_refresh_and_store_cookie(conn, user)

    with {:ok, refresh_token} <- get_cookie_from_resp(conn),
         {:ok, access_token} <- create_access_token(refresh_token) do
      assign_access_token(conn, access_token)
    else
      error ->
        ErrorHandler.auth_error(conn, error, [])
    end
  end

  def get_cookie_from_resp(conn) do
    case conn.resp_cookies do
      %{@token_key => %{value: token}} -> {:ok, token}
      _cookies -> {:unauthenticated, :no_token_found}
    end
  end

  def assign_access_token(conn, access_token) do
    Plug.Conn.put_resp_header(conn, "access_token", access_token)
  end

  def create_refresh_and_store_cookie(conn, user) do
    Guardian.Plug.remember_me(conn, user, %{typ: "refresh"})
  end

  def create_access_token(refresh_token) do
    case Guardian.exchange(refresh_token, "refresh", "access") do
      {:ok, _old, {access_token, _new_claims}} -> {:ok, access_token}
      _err -> {:error, Lenra.Errors.forbidden()}
    end
  end

  def revoke_current_refresh(conn) do
    refresh_token = Guardian.Plug.current_token(conn)
    Guardian.revoke(refresh_token)
    conn
  end
end
