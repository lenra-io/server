Application.load(:application_runner)

for app <- Application.spec(:application_runner, :applications) do
  Application.ensure_all_started(app)
end

Application.ensure_started(:application_runner)

Ecto.Adapters.SQL.Sandbox.mode(ApplicationRunner.Repo, :manual)

Logger.configure(level: :warning)

# Supervisor.start_link(Phoenix.PubSub, name: ApplicationRunner.PubSub)
ApplicationRunner.FakeEndpoint.start_link()

ExUnit.start()
