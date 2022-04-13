defmodule Lenra.Guardian.ErrorHandler do
  @moduledoc """
    Lenra.Guardian.ErrorHandler handle the Guardian Errors
  """

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    message =
      case type do
        :unauthorized ->
          "Unauthorized"

        :invalid_token ->
          "Your token is invalid."

        :unauthenticated ->
          "You are not authenticated"

        :no_resource_found ->
          "No token found in the request, please try again."
      end

    conn
    |> Phoenix.Controller.put_view(LenraWeb.ErrorView)
    |> Plug.Conn.put_status(401)
    |> Phoenix.Controller.render("401.json", message: message)
  end
end
