defmodule ApplicationRunner.Guardian.ErrorHandler do
  @moduledoc """
    ApplicationRunner.Guardian.ErrorHandler handles the Guardian Errors
  """

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler

  def auth_error(conn, %LenraCommon.Errors.BusinessError{} = err, _opts) do
    translated_error = LenraCommonWeb.ErrorHelpers.translate_error(err)

    conn
    |> Phoenix.Controller.put_view(ApplicationRunner.ErrorView)
    |> Plug.Conn.put_status(403)
    |> Phoenix.Controller.render("403.json", translated_error)
  end

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
    |> Phoenix.Controller.put_view(ApplicationRunner.ErrorView)
    |> Plug.Conn.put_status(401)
    |> Phoenix.Controller.render("401.json", %{message: message, reason: type})
  end
end
