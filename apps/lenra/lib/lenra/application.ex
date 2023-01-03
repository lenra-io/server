defmodule Lenra.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    Lenra.MigrationHelper.migrate()

    children = [
      # Start the ecto repository
      Lenra.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Lenra.PubSub},
      # Start guardian Sweeper to delete all expired tokens
      {Guardian.DB.Token.SweeperServer, []},
      # Start the Event Queue
      {EventQueue, &Lenra.LoadWorker.load/0},
      # Start the HTTP Client
      {
        Finch,
        name: FaasHttp,
        pools: %{
          Application.fetch_env!(:lenra, :faas_url) => [size: 32, count: 8]
        }
      },
      {
        Finch,
        name: GitlabHttp,
        pools: %{
          Application.fetch_env!(:lenra, :gitlab_api_url) => [size: 10, count: 3]
        }
      },
      {
        Finch,
        name: UnifiedPushHttp,
        pools: %{
          "http://localhost:8001" => [size: 10, count: 3]
        }
      },
      {Cluster.Supervisor, [Application.get_env(:libcluster, :topologies), [name: Lenra.ClusterSupervisor]]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lenra.Supervisor]

    Logger.info("Lenra Supervisor Starting")
    res = Supervisor.start_link(children, opts)
    Lenra.Seeds.run()
    Logger.info("Lenra Supervisor Started")
    res
  end
end
