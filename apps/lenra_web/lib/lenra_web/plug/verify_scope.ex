defmodule LenraWeb.Plug.VerifyScope do
  use LenraWeb, :controller
  import Plug.Conn

  alias Lenra.Accounts
  alias LenraWeb.Errors.BusinessError

  def init(options) do
    options
  end

  @doc """
    The second parameter "required_scopes" is a comma-separated list of the required scope to accept the connexion.
  """
  def call(conn, required_scopes) do
    with {:ok, token} <- fetch_token(conn),
         {:ok, response} <- check_token(token, required_scopes) do
      subject = response.body["sub"]

      IO.inspect({"Verify Scope", response.body, token})

      conn
      |> put_private(:oauth_token, response.body)
      |> put_private(:guardian_default_resource, Accounts.get_user!(subject))
    else
      err ->
        handle_error(conn)
    end
  end

  defp fetch_token(conn) do
    with [authorization_header] <- get_req_header(conn, "authorization"),
         [_authorization_header, token] <- Regex.run(~r/Bearer (.+)/, authorization_header) do
      {:ok, token}
    else
      _ -> BusinessError.token_not_found_tuple()
    end
  end

  defp check_token(token, required_scopes) do
    with {:ok, response} <- HydraApi.introspect(token, required_scopes),
         true <- Map.get(response.body, "active", false) do
      {:ok, response}
    else
      _ -> BusinessError.invalid_token_tuple()
    end
  end

  defp handle_error(conn) do
    conn
    |> put_view(LenraCommonWeb.BaseView)
    |> assign_error(:forbidden)
    |> reply()
  end
end
