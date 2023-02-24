defmodule LenraWeb.TokenHelper do
  @moduledoc """
    The TokenService module handle the refresh_token and access_token operations
  """
  alias Lenra.Errors.BusinessError
  alias LenraWeb.Guardian
  alias LenraWeb.Guardian.ErrorHandler

  @token_key "guardian_default_token"

  def assign_access_and_refresh_token(%{params: %{"keep" => true}} = conn, user) do
    conn = Guardian.Plug.remember_me(conn, user, %{typ: "refresh"})

    with {:ok, refresh_token} <- get_cookie_from_resp(conn),
         {:ok, access_token} <- create_access_token(refresh_token) do
      assign_access_token(conn, access_token)
    else
      error ->
        ErrorHandler.auth_error(conn, error, [])
    end
  end

  def assign_access_and_refresh_token(conn, user) do
    with {:ok, refresh, _claims} <- Guardian.encode_and_sign(user, %{typ: "refresh"}),
         conn <- Guardian.Plug.put_session_token(conn, refresh, key: "guardian_default") do
      # Do not use create_access_token, sometimes the function returns an error because refresh_token has expired.
      case Guardian.encode_and_sign(user, %{typ: "access"}) do
        {:ok, access_token, _claims} ->
          assign_access_token(conn, access_token)

        error ->
          ErrorHandler.auth_error(conn, error, [])
      end
    end
  end

  def get_cookie_from_resp(conn) do
    case conn.resp_cookies do
      %{@token_key => %{value: token}} -> {:ok, token}
      _cookies -> {:unauthenticated, :no_token_found}
    end
  end

  def assign_access_token(conn, access_token) do
    conn
    |> Plug.Conn.put_resp_header("access_token", access_token)
    |> Plug.Conn.put_resp_header("access-control-expose-headers", "access_token")
  end

  def create_access_token(refresh_token) do
    case Guardian.exchange(refresh_token, "refresh", "access") do
      {:ok, _old, {access_token, _new_claims}} -> {:ok, access_token}
      _err -> BusinessError.forbidden_tuple()
    end
  end

  def revoke_current_refresh(conn) do
    refresh_token = Guardian.Plug.current_token(conn)
    Guardian.revoke(refresh_token)
    conn
  end
end
