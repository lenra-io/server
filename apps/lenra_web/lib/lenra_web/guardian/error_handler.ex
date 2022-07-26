defmodule LenraWeb.Guardian.ErrorHandler do
  @moduledoc """
    LenraWeb.Guardian.ErrorHandler handle the Guardian Errors
  """

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {:error, :did_not_accept_cgu}, _opts) do
    translated_error =
      LenraCommonWeb.ErrorHelpers.translate_error(Lenra.Errors.BusinessError.did_not_accept_cgu_tuple())

    conn
    |> Phoenix.Controller.put_view(LenraWeb.ErrorView)
    |> Plug.Conn.put_status(403)
    |> Phoenix.Controller.render("403.json", error: translated_error)
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

        %LenraCommon.Errors.BusinessError{} = err ->
          err
      end

    conn
    |> Phoenix.Controller.put_view(LenraWeb.ErrorView)
    |> Plug.Conn.put_status(401)
    |> Phoenix.Controller.render("401.json", %{message: message, reason: type})
  end
end
