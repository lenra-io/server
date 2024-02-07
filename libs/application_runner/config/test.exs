import Config

config :application_runner,
  additional_env_modules: {ApplicationRunner.ModuleInjector, :add_env_modules},
  additional_session_modules: {ApplicationRunner.ModuleInjector, :add_session_modules},
  ecto_repos: [ApplicationRunner.Repo],
  faas_url: "http://localhost:1234",
  faas_auth: "Basic YWRtaW46M2kwREc4NTdLWlVaODQ3R0pheW5qMXAwbQ==",
  faas_registry: "registry.gitlab.com/lenra/platform/lenra-ci",
  env: "test"

config :application_runner, ApplicationRunner.Repo,
  username: "postgres",
  password: "postgres",
  database: "applicationrunner_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox,
  log: :debug

config :application_runner, ApplicationRunner.Guardian.AppGuardian,
  issuer: "application_runner",
  secret_key: "5oIBVh2Hauo3LT4knNFu29lX9DYu74SWZfjZzYn+gfr0aryxuYIdpjm8xd0qGGqK"

config :application_runner, ApplicationRunner.FakeEndpoint,
  http: [port: 4002],
  server: false,
  secret_key_base: "jtmuKvO3YYasTYRMAMGs+LSgnBEIFLQIOh439wO3ZoQdSfvDhXrnjKg2R5lCuK04",
  pubsub_server: ApplicationRunner.PubSub

config :swarm,
  sync_nodes_timeout: 0,
  debug: false

config :phoenix, :json_library, Jason

config :bypass, enable_debug_log: false

config :logger,
  level: :none
