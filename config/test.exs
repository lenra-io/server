import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :identity_web, IdentityWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "olVlgvFO2cJT9Xrat5pgN4Dw5fu7E9qKyyK9hL3RLClMlfTVXIsWhSSmbAl/G7TT",
  server: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :lenra_web, LenraWeb.Endpoint,
  http: [port: 4002],
  secret_key_base: "FuEn07fjnCLaC53BiDoBagPYdsv/S65QTfxWgusKP1BA5NiaFzXGYMHLZ6JAYxt1",
  server: false

# Hide logs during test
config :logger, level: :none

# Used to "mock" with Bypass
config :lenra,
  faas_url: "http://localhost:1234",
  faas_auth: "Basic YWRtaW46M2kwREc4NTdLWlVaODQ3R0pheW5qMXAwbQ==",
  faas_registry: "registry.gitlab.com/lenra/platform/lenra-ci",
  runner_callback_url: "http://localhost:4000",
  lenra_env: "test",
  gitlab_api_url: "http://localhost:4567",
  gitlab_api_token: "none",
  gitlab_project_id: "26231009",
  runner_secret: "test_secret",
  gitlab_ci_ref: "master",
  lenra_email: "contact@lenra.io",
  lenra_app_url: "https://localhost:10000",
  pipeline_runner: "gitlab"

config :application_runner,
  faas_url: "http://localhost:1234",
  faas_request_cpu: "50m",
  faas_request_memory: "128Mi",
  faas_limit_cpu: "100m",
  faas_limit_memory: "256Mi"

config :lenra, Lenra.Repo,
  username: "postgres",
  password: "postgres",
  database: "lenra_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox,
  queue_target: 500

config :application_runner, ApplicationRunner.Repo,
  username: "postgres",
  password: "postgres",
  database: "lenra_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox,
  queue_target: 500

config :lenra, Lenra.Mailer, adapter: Bamboo.TestAdapter

config :hydra_api,
  hydra_url: System.get_env("HYDRA_URL", "http://localhost:4405")
