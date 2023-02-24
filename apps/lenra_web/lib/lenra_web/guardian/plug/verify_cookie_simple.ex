defmodule LenraWeb.Plug.VerifyCookieSimple do
  @moduledoc """
    This is a plug that just check and put inside the conn the refresh_token (it does not exchange it for an access_token)
  """
  alias Guardian.Plug.Pipeline

  require Logger

  def init(opt \\ []), do: opt

  def call(conn, opts) do
    with nil <- Guardian.Plug.current_token(conn, opts),
         {:ok, token} <- get_token(conn, opts),
         claims_to_check <- Keyword.get(opts, :claims, %{}),
         key <- Pipeline.fetch_key(conn, opts),
         {:ok, claims} <- LenraWeb.Guardian.decode_and_verify(token, claims_to_check, opts) do
      conn
      |> Guardian.Plug.put_current_token(token, key: key)
      |> Guardian.Plug.put_current_claims(claims, key: key)
    else
      :no_token_found ->
        conn

      {:error, reason} ->
        conn
        |> Pipeline.fetch_error_handler!(opts)
        |> apply(:auth_error, [conn, {:invalid_token, reason}, opts])
        |> Guardian.Plug.maybe_halt(opts)

      _error ->
        conn
    end
  end

  defp get_token(conn, opts) do
    conn = Plug.Conn.fetch_session(conn)

    if Plug.Conn.get_session(conn, :guardian_default_token) == nil do
      Guardian.Plug.find_token_from_cookies(conn, opts)
    else
      {:ok, Plug.Conn.get_session(conn, :guardian_default_token)}
    end
  end
end
