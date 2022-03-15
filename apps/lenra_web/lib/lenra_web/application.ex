defmodule LenraWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LenraWeb.Telemetry,
      # Start the Endpoint (http/https)
      LenraWeb.Endpoint,
      {Cluster.Supervisor, [Application.get_env(:libcluster, :topologies), [name: LenraWeb.ClusterSupervisor]]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LenraWeb.Supervisor]
    Logger.info("LenraWeb Supervisor Starting")
    res = Supervisor.start_link(children, opts)
    Logger.info("LenraWeb Supervisor Started")
    res
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    LenraWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
