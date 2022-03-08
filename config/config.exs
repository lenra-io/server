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
config :lenra, Lenra.Guardian,
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
  url: [host: "localhost"],
  http: [port: {:system, "PORT"}],
  render_errors: [view: LenraWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Lenra.PubSub,
  check_origin: false

config :lenra_web,
  app_url_prefix: "https://#{System.get_env("APP_HOST", "localhost:#{System.get_env("CLIENT_PORT", "10000")}")}/app"

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
  adapter: LenraWeb.ApplicationRunnerAdapter

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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
