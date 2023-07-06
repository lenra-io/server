defmodule LenraWeb.Plug.VerifyScope do
  use LenraWeb, :controller
  import Plug.Conn

  alias Lenra.Accounts
  alias LenraWeb.Errors.BusinessError
  alias LenraWeb.Auth

  def init(options) do
    options
  end

  @doc """
    The second parameter "required_scopes" is a comma-separated list of the required scope to accept the connexion.
  """
  def call(conn, required_scopes) do
    with {:ok, token} <- extract_token(conn),
         {:ok, user, response_body} <- HydraApi.check_token_and_get_resource(token, required_scopes) do
      conn
      |> Auth.put_token_introspect(response_body)
      |> Auth.put_resource(user)
    else
      {:error, :invalid_token} ->
        reply_error(conn, BusinessError.invalid_token())

      {:error, :invalid_subject} ->
        reply_error(conn, BusinessError.invalid_user())

      {:error, err} ->
        reply_error(conn, err)

      err ->
        # Should never raise
        raise err
    end
  end

  defp extract_token(conn) do
    case Auth.current_token(conn) do
      nil -> BusinessError.token_not_found_tuple()
      token -> {:ok, token}
    end
  end

  defp reply_error(conn, error) do
    conn
    |> put_view(LenraCommonWeb.BaseView)
    |> assign_error(error)
    |> reply()
  end
end