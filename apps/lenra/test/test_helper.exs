# Start ExUnit (Unit test module for Elixir)
ExUnit.start()
# Ask SQL adapter to use sandbox connexion pool for the Lenra Repo
Ecto.Adapters.SQL.Sandbox.mode(Lenra.Repo, :manual)
# Initialize the App stub (start the app stub Agent)
Lenra.FaasStub.init()
# Verify that the Bypass app is started before tests
Application.ensure_all_started(:bypass)
