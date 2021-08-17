defmodule LenraWeb.AppChannel do
  @moduledoc """
    `LenraWeb.AppChannel` handle the app channel to run app and listeners and push to the user the resulted UI or Patch
  """
  use Phoenix.Channel

  require Logger

  alias Lenra.{Repo, LenraApplicationServices, Telemetry}
  alias ApplicationRunner.{ActionBuilder, Action}

  def join("app", %{"app" => app_name}, socket) do
    action_logs_uuid = Ecto.UUID.generate()
    app_user_session_uuid = Ecto.UUID.generate()

    Logger.info("Join channel for app : #{app_name}")

    with {:ok, app} <-
           LenraApplicationServices.fetch_by(
             service_name: app_name,
             creator_id: socket.assigns.user.id
           ),
         loaded_app <- Repo.preload(app, main_env: [environment: [:deployed_build]]) do
      build_number = loaded_app.main_env.environment.deployed_build.build_number

      AppChannelMonitor.monitor(self(), %{
        user_id: socket.assigns.user.id,
        app_user_session_uuid: app_user_session_uuid,
        app_name: app_name,
        build_number: build_number
      })

      socket =
        assign(socket,
          app_name: app_name,
          build_number: build_number,
          app_user_session_uuid: app_user_session_uuid,
          action_logs_uuid: action_logs_uuid
        )

      Telemetry.event(:action_logs, %{
        uuid: action_logs_uuid,
        app_user_session_uuid: app_user_session_uuid,
        action: "InitData"
      })

      case ActionBuilder.first_run(%Action{
             action_logs_uuid: action_logs_uuid,
             user_id: socket.assigns.user.id,
             app_name: app_name,
             build_number: build_number
           }) do
        {:ok, ui} ->
          send(self(), {:send_ui, ui})

        {:error, reason} ->
          Logger.error(inspect(reason))
      end

      {:ok, socket}
    else
      _err -> {:error, %{reason: "No app found"}}
    end
  end

  def join("app", _any, _socket) do
    {:error, %{reason: "No App Name"}}
  end

  def handle_info({:send_ui, ui}, socket) do
    push(socket, "ui", ui)
    {:noreply, socket}
  end

  def handle_in("run", %{"code" => action_key, "event" => event}, socket) do
    handle_run(socket, action_key, event)
  end

  def handle_in("run", %{"code" => action_key}, socket) do
    handle_run(socket, action_key)
  end

  defp handle_run(socket, action_key, event \\ %{}) do
    %{
      app_name: app_name,
      user: user,
      build_number: build_number,
      app_user_session_uuid: app_user_session_uuid
    } = socket.assigns

    uuid = Ecto.UUID.generate()

    Telemetry.event(:action_logs, %{
      uuid: uuid,
      app_user_session_uuid: app_user_session_uuid,
      action: action_key
    })

    case ApplicationRunner.ActionBuilder.listener_run(%Action{
           action_logs_uuid: uuid,
           user_id: user.id,
           app_name: app_name,
           build_number: build_number,
           action_key: action_key,
           event: event
         }) do
      {:ok, patch} ->
        push(socket, "patchUi", %{patch: patch})

      {:error, reason} ->
        Logger.error(reason)
    end

    {:noreply, socket}
  end
end
