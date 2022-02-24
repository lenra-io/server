defmodule LenraWeb.AppChannel do
  @moduledoc """
    `LenraWeb.AppChannel` handle the app channel to run app and listeners and push to the user the resulted UI or Patch
  """
  use Phoenix.Channel
  alias ApplicationRunner.{SessionManager, SessionManagers}

  alias Lenra.{
    Environment,
    LenraApplication,
    LenraApplicationServices,
    Repo,
    UserEnvironmentAccessServices
  }

  alias LenraWeb.ErrorHelpers

  require Logger

  def join("app", %{"app" => app_name}, socket) do
    # action_logs_uuid = Ecto.UUID.generate()
    session_id = Ecto.UUID.generate()
    user = socket.assigns.user

    Logger.debug("Joining channel for app : #{app_name}")

    with {:ok, _uuid} <- Ecto.UUID.cast(app_name),
         {:ok, app} <-
           LenraApplicationServices.fetch_by(service_name: app_name),
         %LenraApplication{} = application <-
           Repo.preload(app, main_env: [environment: [:deployed_build]]),
         {:ok, :authorized} <- get_app_authorization(user.id, application) do
      %Environment{} = environment = select_env(application)

      Logger.debug("Environment selected is #{environment.name}")

      # Assign the session_id to the socket for future usage
      socket = assign(socket, session_id: session_id)

      # prepare the assigns to the session/environment
      session_assigns = %{
        user: user,
        application: application,
        environment: environment,
        socket_pid: self()
      }

      env_assigns = %{application: application, environment: environment}

      with {:ok, session_pid} <-
             start_session(environment.id, session_id, session_assigns, env_assigns),
           :ok <- SessionManager.init_data(session_pid) do
        {:ok, assign(socket, session_pid: session_pid)}
      else
        # Application error
        {:error, reason} when is_bitstring(reason) ->
          {:error, %{reason: [%{code: -1, message: reason}]}}

        {:error, reason} when is_atom(reason) ->
          {:error, %{reason: ErrorHelpers.translate_error(reason)}}
      end
    else
      {:error, :not_authorized} ->
        {:error, %{reason: ErrorHelpers.translate_error(:no_app_authorization)}}

      _err ->
        {:error, %{reason: ErrorHelpers.translate_error(:no_app_found)}}
    end
  end

  def join("app", _any, _socket) do
    {:error, %{reason: ErrorHelpers.translate_error(:no_app_found)}}
  end

  defp get_app_authorization(user_id, app) do
    cond do
      user_id == app.creator_id ->
        {:ok, :authorized}

      select_env(app).is_public ->
        {:ok, :authorized}

      true ->
        case UserEnvironmentAccessServices.fetch_by(
               environment_id: select_env(app).id,
               user_id: user_id
             ) do
          {:ok, _access} -> {:ok, :authorized}
          _any -> {:error, :not_authorized}
        end
    end
  end

  defp select_env(%LenraApplication{} = app) do
    app.main_env.environment
  end

  defp start_session(env_id, session_id, session_assigns, env_assigns) do
    case SessionManagers.start_session(session_id, env_id, session_assigns, env_assigns) do
      {:ok, session_pid} -> {:ok, session_pid}
      {:error, message} -> {:error, message}
    end
  end

  def handle_info({:send, :ui, ui}, socket) do
    Logger.debug("send ui #{inspect(ui)}")
    push(socket, "ui", ui)
    {:noreply, socket}
  end

  def handle_info({:send, :patches, patches}, socket) do
    Logger.debug("send patchUi  #{inspect(%{patch: patches})}")

    push(socket, "patchUi", %{"patch" => patches})
    {:noreply, socket}
  end

  def handle_info({:send, :error, reason}, socket) do
    Logger.debug("send error  #{inspect(%{error: reason})}")

    case is_atom(reason) do
      true -> push(socket, "error", %{"errors" => ErrorHelpers.translate_error(reason)})
      # Application error
      false -> push(socket, "error", %{"errors" => [%{code: -1, message: reason}]})
    end

    {:noreply, socket}
  end

  def handle_in("run", %{"code" => code, "event" => event}, socket) do
    handle_run(socket, code, event)
  end

  def handle_in("run", %{"code" => code}, socket) do
    handle_run(socket, code)
  end

  defp handle_run(socket, code, event \\ %{}) do
    %{
      session_pid: session_pid
    } = socket.assigns

    Logger.debug("Handle run #{code}")
    SessionManager.run_listener(session_pid, code, event)

    {:noreply, socket}
  end
end
