defmodule LenraWeb.Plug.VerifyScope do
  @moduledoc """
    This plug check the scope contained in the token by using the introspect function from Hydra.
    First it gets the token previously extracted by "extract_query_params" or "extract_bearer" plug.
    Then, if the token exists and the scope(s) matches, it put the introspect & resource in the conn.
    Otherwise, it halt the connexion and return an error.
  """
  use LenraWeb, :controller
  import Plug.Conn

  alias Lenra.Accounts
  alias LenraWeb.Auth
  alias LenraWeb.Errors.BusinessError

  def init(options) do
    options
  end

  @doc """
    The second parameter "required_scopes" is a comma-separated list of the required scope to accept the connexion.
  """
  def call(conn, required_scopes) do
    with {:ok, token} <- extract_token(conn),
         {:ok, subject, response_body} <- HydraApi.check_token_and_get_subject(token, required_scopes),
         %Lenra.Accounts.User{} = user <- Accounts.get_user(subject) do
      conn
      |> Auth.put_token_introspect(response_body)
      |> Auth.put_resource(user)
    else
      {:error, :invalid_token} ->
        conn
        |> reply_error(BusinessError.invalid_token())
        |> halt()

      {:error, err} ->
        conn
        |> reply_error(err)
        |> halt()

      nil ->
        conn
        |> reply_error(BusinessError.invalid_token())
        |> halt()

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
