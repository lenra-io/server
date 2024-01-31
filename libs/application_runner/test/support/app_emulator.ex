defmodule ApplicationRunner.AppEmulator do
  use GenServer
  require Logger

  @moduledoc """
    Emulates a Lenra app.
  """

  @enforce_keys [:app_name]
  defstruct [
    :app_name
  ]

  @type t :: %__MODULE__{
          app_name: String.t()
        }

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl true
  def init(_) do
    bypass = Bypass.open(port: 1234)
    {:ok, bypass: bypass, apps: %{}}
  end

  # def new() do
  #   start_link([])
  # end

  # def manifest(%AppEmulator{app_name: app_name}, manifest) do
  #   GenServer.call(__MODULE__, {:set_manifest, app_name, manifest})
  # end

  # def map(%AppEmulator{app_name: app_name}, request, response) do
  #   %{app_emulator | manifest: manifest}
  # end

  # def handle_call({:set_manifest, app_name, manifest}, _from, state) do
  #   {state, app} = start_app(state, app_name)
  #   {:reply, {:ok}, save_app(state, app_name, Map.put(app, :manifest, manifest))}
  # end

  # def handle_call({:call, app_name, request}, _from, state) do
  #   {state, app} = start_app(state, app_name)
  #   reponse = handle_request(app, request)
  #   {:reply, app.manifest, state}
  # end

  # defp handle_request([requests: requests, manifest: manifest], request) do
  #   case request do
  #     %{"view" => view} ->
  #       {:ok, %{"_type" => "text", "text" => "Hello World"}}

  #     _ ->
  #       Logger.error("Unknown request #{inspect(request)}")
  #       {:ok, manifest}
  #   end
  # end

  # defp start_app([apps: apps] = state, app_name) do
  #   case apps[app_name] do
  #     nil ->
  #       Logger.debug("start app #{app_name}")

  #       Bypass.stub(bypass, "POST", "/function/#{app_name}", fn conn ->
  #         {:ok, body, conn} = Plug.Conn.read_body(conn)
  #         Logger.debug("call app #{app_name} with body #{inspect(body)}")
  #         result = GenServer.call(__MODULE__, {:call, app_name, body})

  #         case result do
  #           {:ok, response} ->
  #             Plug.Conn.resp(conn, 200, Jason.encode!(response))

  #           {:error, response} ->
  #             Plug.Conn.resp(conn, 500, Jason.encode!(response))
  #         end
  #       end)

  #       app = [requests: %{}, manifest: nil]
  #       state = save_app(state, app_name, app)

  #       {state, app}

  #     app ->
  #       Logger.debug("app #{app_name} already started")
  #       {state, app}
  #   end
  # end

  # defp save_app([apps: apps] = state, app_name, app) do
  #   apps = Map.put(apps, app_name, app)
  #   state |> Map.put(:apps, apps)
  # end
end
