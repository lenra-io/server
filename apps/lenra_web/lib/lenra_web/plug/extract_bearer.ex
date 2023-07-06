defmodule LenraWeb.Plug.ExtractBearer do
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
    with [authorization_header] <- get_req_header(conn, "authorization"),
         [_authorization_header, token] <- Regex.run(~r/Bearer (.+)/, authorization_header) do
      {:ok, token}
    else
      _ -> conn
    end
  end
end
