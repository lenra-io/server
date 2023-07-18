defmodule LenraWeb.Plug.ExtractQueryParams do
  @moduledoc """
    This plug extract the token from the QueryParams (if exist) and put it in the conn.
    If the token doest not exist in the QueryParams, does nothing.
  """
  use LenraWeb, :controller
  import Plug.Conn

  alias LenraWeb.Auth

  def init(options) do
    options
  end

  @doc """
    Try to extract the token from the authorization bearer
  """
  def call(conn) do
    with {:ok, token} <- extract_token(conn) do
      Auth.put_token(conn, token)
    end
  end

  defp extract_token(conn) do
    conn = Plug.Conn.fetch_query_params(conn)

    case conn.params["token"] do
      nil -> conn
      token -> {:ok, token}
    end
  end
end
