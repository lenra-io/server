defmodule Lenra.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  alias Crontab.CronExpression.Parser

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
         name: GitlabHttp,
         pools: %{
           Application.fetch_env!(:lenra, :gitlab_api_url) => [size: 10, count: 3]
         }},
        id: :finch_gitlab_http
      ),
      {Cluster.Supervisor, [Application.get_env(:libcluster, :topologies), [name: Lenra.ClusterSupervisor]]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lenra.Supervisor]

    Logger.info("Lenra Supervisor Starting")
    res = Supervisor.start_link(children, opts)
    Application.ensure_all_started(:application_runner) |> IO.inspect()

    Lenra.Repo.all(ApplicationRunner.Crons.Cron)
    |> Enum.each(fn cron ->
      {:ok, schedule} = Parser.parse(cron.schedule)

      IO.inspect(cron)

      ApplicationRunner.Scheduler.new_job(
        name: cron.name,
        overlap: cron.overlap,
        state: cron.state,
        timezone: cron.timezone,
        schedule: schedule
      )
      |> Quantum.Job.set_task(
        {CronServices, :run_cron, [cron.app_name, cron.listener_name, cron.props, %{}, cron.env_id]}
      )
      |> ApplicationRunner.Scheduler.add_job()
    end)

    Lenra.Seeds.run()
    Logger.info("Lenra Supervisor Started")
    res
  end
end
