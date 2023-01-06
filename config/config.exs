# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.

# This is the BASE config, loaded at build time and it will be override by other configs

# General application configuration
import Config
# Configure the repo
config :lenra,
  ecto_repos: [Lenra.Repo]

config :lenra, Lenra.Repo,
  migration_timestamps: [type: :utc_datetime],
  pool_size: 10

# Configure Guardian
config :lenra_web, LenraWeb.Guardian,
  issuer: "lenra",
  secret_key: "5oIBVh2Hauo3LT4knNFu29lX9DYu74SWZfjZzYn+gfr0aryxuYIdpjm8xd0qGGqK"

config :application_runner, ApplicationRunner.Guardian.AppGuardian,
  issuer: "lenra",
  secret_key: "5oIBVh2Hauo3LT4knNFu29lX9DYu74SWZfjZzYn+gfr0aryxuYIdpjm8xd0qGGqK"

# Configure Guardian DB
config :guardian, Guardian.DB,
  repo: Lenra.Repo,
  schema_name: "guardian_tokens",
  token_types: ["refresh"],
  sweep_interval: 60

# Configure bamboo
config :lenra, Lenra.Mailer,
  adapter: Bamboo.SendGridAdapter,
  hackney_opts: [
    recv_timeout: :timer.minutes(1),
    connect_timeout: :timer.minutes(1)
  ]

# Configures the endpoint
config :lenra_web, LenraWeb.Endpoint,
  url: [host: "localhost", port: System.get_env("PORT", "4000")],
  http: [port: {:system, "PORT"}],
  render_errors: [view: LenraWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Lenra.PubSub,
  check_origin: false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure JSON validator
# The JsonSchemata dependency is defined here because the only way to have the ex_json_schema
# library working is by defining the remote_schema_resolver in the config.
# The config cannot be read from the ApplicationRunner library's config directly so it has to be set here.
# See https://github.com/jonasschmidt/ex_json_schema#loading-remote-schemata
config :ex_component_schema,
       :remote_schema_resolver,
       {ApplicationRunner.JsonSchemata, :read_schema}

config :application_runner,
  lenra_environment_table: "environments",
  lenra_user_table: "users",
  repo: Lenra.Repo,
  url: System.get_env("HOST", "4000"),
  faas_url: System.get_env("FAAS_URL", "https://openfaas-dev.lenra.me"),
  faas_auth: System.get_env("FAAS_AUTH", "Basic YWRtaW46Z0Q4VjNHR1YxeUpS"),
  faas_registry: System.get_env("FAAS_REGISTRY", "registry.gitlab.com/lenra/platform/lenra-ci"),
  env: Mix.env() |> Atom.to_string(),
  listeners_timeout: System.get_env("LISTENERS_TIMEOUT", 1 * 60 * 60 * 1000),
  view_timeout: System.get_env("VIEW_TIMEOUT", 1 * 30 * 1000),
  manifest_timeout: System.get_env("MANIFEST_TIMEOUT", 1 * 30 * 1000),

config :application_runner, :mongo,
  hostname: System.get_env("MONGO_HOSTNAME", "localhost"),
  port: System.get_env("MONGO_PORT", "27017"),
  username: System.get_env("MONGO_USERNAME"),
  password: System.get_env("MONGO_PASSWORD"),
  ssl: System.get_env("MONGO_SSL", "false"),
  auth_source: System.get_env("MONGO_AUTH_SOURCE")

# additional_session_modules: {LenraWeb.ApplicationRunnerAdapter, :additional_session_modules},
# additional_env_modules: {LenraWeb.ApplicationRunnerAdapter, :additional_env_modules}

config :lenra,
  faas_secrets: []

config :argon2_elixir,
  t_cost: 8,
  m_cost: 15,
  parallelism: 4,
  argon2_type: 2

# Enable sentry configuration. Sentry will catch all errors on staging and production environment.
# The source file are linked to sentry.
config :sentry,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  included_environments: ~w(production staging)

# Add sentry as logger backend (as well as console logging)
config :logger, backends: [:console, Sentry.LoggerBackend]

# Ask sentry to log Logger.error messages (not only stacktrace)
config :logger, Sentry.LoggerBackend,
  level: :error,
  capture_log_messages: true

config :libcluster,
  topologies: [
    lenra: [
      # The selected clustering strategy. Required.
      strategy: Cluster.Strategy.Epmd,
      config: [hosts: []]
    ]
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
