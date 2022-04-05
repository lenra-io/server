defmodule LenraWeb.Plugs.CheckCguPlug do
  def init(opts), do: opts

  def call(conn, _opts) do
    user = Guardian.Plug.current_resource(conn)

    if Lenra.CguServices.user_accepted_latest_cgu?(user.id) do
      conn
    else
      [translated_error] = LenraWeb.ErrorHelpers.translate_error(:did_not_accept_cgu)

      conn
      |> Phoenix.Controller.put_view(LenraWeb.ErrorView)
      |> Plug.Conn.put_status(403)
      |> Phoenix.Controller.render("403.json", error: translated_error)
      |> Plug.Conn.halt()
    end
  end
end
