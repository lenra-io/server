defmodule ApplicationRunner.RoutesChannel do
  @moduledoc """
    `ApplicationRunner.RoutesChannel` handles the app channel to run app and listeners and push to the user the resulted UI or Patch
  """
  use SwarmNamed

  defmacro __using__(_opts) do
    quote do
      use Phoenix.Channel

      alias ApplicationRunner.Environment
      alias ApplicationRunner.Guardian.AppGuardian
      alias ApplicationRunner.Session
      alias ApplicationRunner.Session.UiBuilders.JsonBuilder
      alias ApplicationRunner.Session.UiBuilders.LenraBuilder

      alias LenraCommonWeb.ErrorHelpers

      alias ApplicationRunner.Errors.BusinessError

      require Logger

      def join("routes", %{"mode" => "lenra"}, socket) do
        env_id = socket.assigns.env_id
        session_id = socket.assigns.session_id

        res = %{
          "lenraRoutes" => LenraBuilder.get_routes(env_id)
        }

        case Swarm.register_name(get_swarm_name(session_id), self()) do
          :yes ->
            {:ok, res, socket}

          :no ->
            metadata = %{
              session_id: session_id,
              route: "routes"
            }

            Logger.critical(
              metadata
              |> BusinessError.could_not_register_appchannel()
            )

            metadata
            |> BusinessError.could_not_register_appchannel_tuple()
        end
      end

      def join("routes", %{"mode" => "json"}, socket) do
        env_id = socket.assigns.env_id

        res = %{"jsonRoutes" => JsonBuilder.get_routes(env_id)}

        {:ok, res, socket}
      end

      def join(_, _any, _socket) do
        {:error, ErrorHelpers.translate_error(BusinessError.invalid_channel_name())}
      end

      ########
      # INFO #
      ########

      # Send new route to client
      def handle_info({:send, :navTo, route}, socket) do
        Logger.debug("send route #{inspect(route)}")
        push(socket, "navTo", route)
        {:noreply, socket}
      end

      def get_swarm_name(session_id) do
        ApplicationRunner.RoutesChannel.get_name(session_id)
      end
    end
  end
end
