import Config
# We don't run a server during test. If one is required,
# you can enable the server option below.
config :lenra_web, LenraWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

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
  runner_secret: "test_secret"

config :lenra, Lenra.Repo,
  username: "postgres",
  password: "postgres",
  database: "lenra_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox

config :lenra, Lenra.Mailer, adapter: Bamboo.TestAdapter
