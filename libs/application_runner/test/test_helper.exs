Application.load(:application_runner)

for app <- Application.spec(:application_runner, :applications) do
  Application.ensure_all_started(app)
end

Application.ensure_started(:application_runner)

Ecto.Adapters.SQL.Sandbox.mode(ApplicationRunner.Repo, :manual)

Logger.configure(level: :warning)

ApplicationRunner.FakeEndpoint.start_link()

ExUnit.start()
