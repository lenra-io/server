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
    SessionStateServices
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
         :ok <- Bouncer.allow(LenraWeb.AppChannel.Policy, :join_app, user, application) do
      %Environment{} = environment = select_env(application)

      SessionStateServices.create_and_assign_token(session_id, user.id, environment.id)

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

      case start_session(environment.id, session_id, session_assigns, env_assigns) do
        {:ok, session_pid} ->
          {:ok, assign(socket, session_pid: session_pid)}

        # Application error
        {:error, reason} when is_bitstring(reason) ->
          {:error, %{reason: [%{code: -1, message: reason}]}}

        {:error, reason} when is_atom(reason) ->
          {:error, %{reason: ErrorHelpers.translate_error(reason)}}
      end
    else
      {:error, :forbidden} ->
        {:error, %{reason: ErrorHelpers.translate_error(:no_app_authorization)}}

      _err ->
        {:error, %{reason: ErrorHelpers.translate_error(:no_app_found)}}
    end
  end

  def join("app", _any, _socket) do
    {:error, %{reason: ErrorHelpers.translate_error(:no_app_found)}}
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

  def handle_info({:send, :error, {:error, reason}}, socket) when is_atom(reason) do
    Logger.error("Send error #{inspect(reason)}")

    push(socket, "error", %{"errors" => ErrorHelpers.translate_error(reason)})
    {:noreply, socket}
  end

  def handle_info({:send, :error, {:error, :invalid_ui, errors}}, socket) when is_list(errors) do
    formatted_errors =
      errors
      |> Enum.map(fn {message, path} -> %{code: 0, message: "#{message} at path #{path}"} end)

    push(socket, "error", %{"errors" => formatted_errors})
    {:noreply, socket}
  end

  def handle_info({:send, :error, reason}, socket) when is_atom(reason) do
    Logger.error("Send error atom #{inspect(reason)}")
    push(socket, "error", %{"errors" => ErrorHelpers.translate_error(reason)})
    {:noreply, socket}
  end

  def handle_info({:send, :error, malformatted_error}, socket) do
    Logger.error("Malformatted error #{inspect(malformatted_error)}")
    push(socket, "error", %{"errors" => ErrorHelpers.translate_error(:unknow_error)})
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
    SessionManager.send_client_event(session_pid, code, event)

    {:noreply, socket}
  end
end

defmodule LenraWeb.AppChannel.Policy do
  @moduledoc """
    This policy defines the rules to join an application.
    The admin can join any app.
  """
  @behaviour Bouncer.Policy

  @impl true
  def authorize(_action, %Lenra.User{role: :admin}, _metadata), do: true

  def authorize(:join_app, %Lenra.User{id: id}, %Lenra.LenraApplication{creator_id: id}), do: true

  def authorize(:join_app, _user, %Lenra.LenraApplication{
        main_env: %Lenra.ApplicationMainEnv{environment: %Lenra.Environment{is_public: true}}
      }),
      do: true

  def authorize(:join_app, user, app) do
    case Lenra.UserEnvironmentAccessServices.fetch_by(
           environment_id: app.main_env.environment.id,
           user_id: user.id
         ) do
      {:ok, _access} -> true
      _any -> false
    end
  end

  def authorize(_action, _resource, _metadata), do: false
end
