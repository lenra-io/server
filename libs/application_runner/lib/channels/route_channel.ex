# credo:disable-for-this-file Credo.Check.Refactor.LongQuoteBlocks
defmodule ApplicationRunner.RouteChannel do
  @moduledoc """
    `ApplicationRunner.RouteChannel` handle the app channel to run app and listeners and push to the user the resulted UI or Patch
  """
  alias ApplicationRunner.Telemetry

  defmacro __using__(_opts) do
    quote do
      use Phoenix.Channel
      use SwarmNamed

      alias ApplicationRunner.Environment
      alias ApplicationRunner.Guardian.AppGuardian
      alias ApplicationRunner.Session

      alias LenraCommonWeb.ErrorHelpers

      alias ApplicationRunner.Errors.{BusinessError, TechnicalError}
      alias LenraCommon.Errors.DevError

      require Logger

      def join("route:" <> route, params, socket) do
        mode = Map.get(params, "mode", "lenra")
        session_id = socket.assigns.session_id
        Logger.debug("Join for #{session_id}, with params: #{inspect(params)}")

        with sm <- Session.MetadataAgent.get_metadata(session_id),
             :yes <- Swarm.register_name(get_name({session_id, mode, route}), self()),
             :ok <- Swarm.join(get_group(session_id, mode, route), self()),
             {:ok, _pid} <-
               Session.RouteDynSup.ensure_child_started(sm.env_id, session_id, mode, route) do
          Logger.notice("Route #{route}, in mode #{mode}, open for session: #{session_id}")
          {:ok, socket}
        else
          :no ->
            Logger.critical(BusinessError.could_not_register_appchannel(%{session_id: session_id, route: route}))

            BusinessError.could_not_register_appchannel_tuple(%{
              session_id: session_id,
              route: route
            })

          err ->
            err
        end
      end

      def join(_, _any, _socket) do
        Telemetry.event(:alert, %{}, BusinessError.invalid_channel_name())
        {:error, ErrorHelpers.translate_error(BusinessError.invalid_channel_name())}
      end

      ######
      # IN #
      ######

      # Receive run request from client, with event
      def handle_in("run", %{"code" => code, "event" => event}, socket) do
        handle_run(socket, code, event)
      end

      # Receive run request from client
      def handle_in("run", %{"code" => code}, socket) do
        handle_run(socket, code)
      end

      # Call send_client_event to run listener
      def handle_run(socket, code, event \\ %{}) do
        session_id = Map.fetch!(socket.assigns, :session_id)

        Logger.debug("Handle run #{code}")
        start_time = Time.utc_now()

        case Session.send_client_event(session_id, code, event) do
          {:error, err} ->
            duration = Time.diff(Time.utc_now(), start_time, :millisecond)
            Logger.debug("/Handle run #{code} failed (#{duration} ms)")
            Phoenix.Channel.push(socket, "error", ErrorHelpers.translate_error(err))
            {:reply, {:error, %{"error" => err}}, socket}

          _ ->
            duration = Time.diff(Time.utc_now(), start_time, :millisecond)
            Logger.debug("/Handle run #{code} succeed (#{duration} ms)")
            {:reply, {:ok, %{}}, socket}
        end
      end

      ########
      # INFO #
      ########

      # Send new ui to client
      def handle_info({:send, :ui, ui}, socket) do
        Logger.debug("send ui #{inspect(ui)}")
        push(socket, "ui", ui)
        {:noreply, socket}
      end

      # Send patch ui to client
      def handle_info({:send, :patches, patches}, socket) do
        Logger.debug("send patchUi  #{inspect(%{patch: patches})}")

        push(socket, "patchUi", %{"patch" => patches})
        {:noreply, socket}
      end

      # Send error in error channel
      def handle_info({:send, :error, {:error, err}}, socket) when is_struct(err) do
        # Log a debug, normally errors are logged before sending the error to the channel.
        Logger.debug("Send error #{inspect(err)}")

        push(socket, "error", ErrorHelpers.translate_error(err))
        {:noreply, socket}
      end

      # Send an error if the ui is malformed
      def handle_info({:send, :error, {:error, :invalid_ui, errors}}, socket)
          when is_list(errors) do
        formatted_errors =
          errors
          |> Enum.map(fn {message, path} ->
            %{message: "#{message} at path #{path}", reason: "invalid_ui"}
          end)

        Logger.warning("Channel error: #{inspect(formatted_errors)}")

        push(socket, "error", %{"errors" => formatted_errors})
        {:noreply, socket}
      end

      def handle_info({:send, :error, malformatted_error}, socket) do
        Logger.error("Malformatted error #{inspect(malformatted_error)}")

        push(socket, "error", %{
          "errors" => ErrorHelpers.translate_error(TechnicalError.unknown_error())
        })

        {:noreply, socket}
      end

      def get_group(session_id, mode, route) do
        ApplicationRunner.RouteChannel.get_group(session_id, mode, route)
      end
    end
  end

  @spec get_group(any, any, any) :: {ApplicationRunner.RouteChannel, any, any, any}
  def get_group(session_id, mode, route) do
    {__MODULE__, session_id, mode, route}
  end
end
