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
      Supervisor.child_spec(
        {Finch,
         name: FaasHttp,
         pools: %{
           Application.fetch_env!(:lenra, :faas_url) => [size: 32, count: 8]
         }},
        id: :finch_faas_http
      ),
      Supervisor.child_spec(
        {Finch,
         name: PipelineHttp,
         pools:
           case String.downcase(Application.fetch_env!(:lenra, :pipeline_runner)) do
             "gitlab" ->
               %{
                 Application.fetch_env!(:lenra, :gitlab_api_url) => [
                   size: 10,
                   count: 3
                 ]
               }

             "kubernetes" ->
               %{
                 Application.fetch_env!(:lenra, :kubernetes_api_url) => [
                   size: 10,
                   count: 3,
                   conn_opts: [
                     transport_opts: [
                       cacertfile: Application.fetch_env!(:lenra, :kubernetes_api_cert)
                     ]
                   ]
                 ]
               }

             _anything ->
               BusinessError.pipeline_runner_unkown_service_tuple()
           end},
        id: :finch_gitlab_http
      ),
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
