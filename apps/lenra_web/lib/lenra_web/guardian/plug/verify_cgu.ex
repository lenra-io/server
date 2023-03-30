defmodule LenraWeb.Plug.VerifyCgu do
  @moduledoc """
  Plug that checks whether the latest cgu has been accepted or not
  """

  alias Lenra.Errors.BusinessError

  def init(opts), do: opts

  def call(conn, _opts) do
    user = Guardian.Plug.current_resource(conn)

    if Lenra.Legal.user_accepted_latest_cgu?(user.id) do
      conn
    else
      translated_error = LenraCommonWeb.ErrorHelpers.translate_error(BusinessError.did_not_accept_cgu_tuple())

      conn
      |> Phoenix.Controller.put_view(LenraWeb.ErrorView)
      |> Plug.Conn.put_status(403)
      |> Phoenix.Controller.render("403.json", error: translated_error)
      |> Plug.Conn.halt()
    end
  end
end