defmodule ApplicationRunner.AppSocket do
  defmacro __using__(opts) do
    route_channel = Keyword.fetch!(opts, :route_channel)
    routes_channel = Keyword.fetch!(opts, :routes_channel)
    adapter_mod = Keyword.fetch!(opts, :adapter)

    quote do
      require Logger
      use Phoenix.Socket
      alias ApplicationRunner.AppSocket
      alias ApplicationRunner.Errors.TechnicalError
      alias ApplicationRunner.Monitor
      alias ApplicationRunner.Session
      alias ApplicationRunner.Telemetry
      alias LenraCommon.Errors
      alias LenraCommonWeb.ErrorHelpers

      @adapter_mod unquote(adapter_mod)

      defoverridable init: 1

      ## Channels
      channel("route:*", unquote(route_channel))
      channel("routes", unquote(routes_channel))

      @impl true
      def init(state) do
        res = {:ok, {_, socket}} = super(state)
        Monitor.SessionMonitor.monitor(self(), socket.assigns)
        res
      end

      # Socket params are passed from the client and can
      # be used to verify and authenticate a user. After
      # verification, you can put default assigns into
      # the socket that will be set for all channels, ie
      #
      #     {:ok, assign(socket, :user_id, verified_user_id)}
      #
      # To deny connection, return `:error`.
      #
      # See `Phoenix.Token` documentation for examples in
      # performing token verification on connect.
      @impl true
      def connect(params, socket, _connect_info) do
        with {:ok, user_id, roles, app_name, context} <-
               @adapter_mod.resource_from_params(params),
             :ok <- @adapter_mod.allow(user_id, app_name),
             {:ok, env_metadata, session_metadata} <-
               ApplicationRunner.AppSocket.create_metadatas(
                 @adapter_mod,
                 user_id,
                 roles,
                 app_name,
                 context
               ),
             start_time <- Telemetry.start(:app_session, session_metadata),
             {:ok, session_pid} <- Session.start_session(session_metadata, env_metadata) do
          Logger.notice("Joined app #{app_name} with params #{inspect(params)}")

          Logger.debug(
            "#{app_name}: /n/t session_metadata: #{inspect(session_metadata)} /n/t env_metadata: #{inspect(env_metadata)}"
          )

          socket =
            socket
            |> assign(env_id: session_metadata.env_id)
            |> assign(session_id: session_metadata.session_id)
            |> assign(user_id: user_id)
            |> assign(roles: roles)
            |> assign(start_time: start_time)

          {:ok, socket}
        else
          {:error, reason} when is_bitstring(reason) ->
            Logger.warning(%{message: reason, reason: "application_error"})
            {:error, %{message: reason, reason: "application_error"}}

          {:error, reason} when is_struct(reason) ->
            Logger.error(reason)
            {:error, ErrorHelpers.translate_error(reason)}

          {:error, reason} ->
            reason
            |> Errors.format_error_with_stacktrace()
            |> Logger.error()

            {:error, ErrorHelpers.translate_error(TechnicalError.unknown_error())}
        end
      end

      # Socket id's are topics that allow you to identify all sockets for a given user:
      #
      #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
      #
      # Would allow you to broadcast a "disconnect" event and terminate
      # all active sockets and channels for a given user:
      #
      #     LenraWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
      #
      # Returning `nil` makes this socket anonymous.
      @impl true
      def id(socket), do: "app_socket:#{socket.assigns.user_id}"
    end
  end

  require Logger
  alias ApplicationRunner.Environment
  alias ApplicationRunner.Errors.BusinessError
  alias ApplicationRunner.Session

  def create_metadatas(adapter_mod, user_id, roles, app_name, context) do
    session_id = Ecto.UUID.generate()

    with function_name when is_bitstring(function_name) <-
           adapter_mod.get_function_name(app_name),
         env_id <- adapter_mod.get_env_id(app_name) do
      # prepare the assigns to the session/environment
      session_metadata = %Session.Metadata{
        env_id: env_id,
        session_id: session_id,
        user_id: user_id,
        roles: roles,
        function_name: function_name,
        context: context
      }

      env_metadata = %Environment.Metadata{
        env_id: env_id,
        function_name: function_name
      }

      {:ok, env_metadata, session_metadata}
    else
      {:error, :forbidden} ->
        {:error, BusinessError.forbidden()}

      err ->
        err
    end
  end

  def extract_params(params) do
    with {:ok, app_name} <- extract_appname(params) do
      context = extract_context(params)
      {:ok, app_name, context}
    end
  end

  def extract_context(params) do
    case Map.get(params, "context", %{}) do
      res when is_map(res) -> res
      _not_map -> %{}
    end
  end

  def extract_appname(params) do
    app_name = Map.get(params, "app")

    if is_nil(app_name) do
      BusinessError.no_app_found_tuple()
    else
      {:ok, app_name}
    end
  end
end
