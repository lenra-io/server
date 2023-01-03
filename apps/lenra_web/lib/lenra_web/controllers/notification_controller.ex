defmodule LenraWeb.NotificationController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.NotificationController.Policy

  import Plug.Conn

  require Logger

  alias Lenra.Notifications
  alias LenraWeb.Guardian.Plug

  def put_provider(conn, params) do
    with :ok <- allow(conn),
         user <- Plug.current_resource(conn) do
      params
      |> Map.put("user_id", user.id)
      |> Notifications.set_notify_provider()
    end
  end
end

defmodule LenraWeb.NotificationController.Policy do
  @impl Bouncer.Policy
  def authorize(:put_provider, _user, _data), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
