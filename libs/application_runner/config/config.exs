import Config

config :phoenix, :json_library, Jason

# Configure JSON validator
config :ex_component_schema,
       :remote_schema_resolver,
       {ApplicationRunner.JsonSchemata, :read_schema}

config :application_runner,
  # 10 min
  session_inactivity_timeout: 1000 * 60 * 10,
  # 60 min
  env_inactivity_timeout: 1000 * 60 * 60,
  # 10 min
  query_inactivity_timeout: 1000 * 60 * 10,
  # 1 hour
  listeners_timeout: 1 * 60 * 60 * 1000,
  # 30 s
  view_timeout: 1 * 30 * 1000,
  manifest_timeout: 1 * 30 * 1000,
  lenra_environment_table: "environments",
  lenra_user_table: "users",
  repo: ApplicationRunner.Repo,
  internal_api_url: "http://localhost:4000",
  env: "dev",
  faas_url: System.get_env("FAAS_URL", "https://openfaas-dev.lenra.me"),
  faas_auth: System.get_env("FAAS_AUTH", "Basic YWRtaW46Z0Q4VjNHR1YxeUpS"),
  faas_registry: System.get_env("FAAS_REGISTRY", "registry.gitlab.com/lenra/platform/lenra-ci"),
  faas_secrets: [],
  scale_to_zero: true,
  faas_request_cpu: System.get_env("FAAS_REQUEST_CPU", "50m"),
  faas_request_memory: System.get_env("FAAS_REQUEST_MEMORY", "128Mi"),
  faas_limit_cpu: System.get_env("FAAS_LIMIT_CPU", "100m"),
  faas_limit_memory: System.get_env("FAAS_LIMIT_MEMORY", "256Mi")

config :application_runner, :mongo,
  hostname: "localhost",
  port: "27017",
  ssl: false

config :application_runner,
  ecto_repos: [ApplicationRunner.Repo]

config :application_runner, ApplicationRunner.Repo,
  database: "file::memory:?cache=shared",
  log: false

config :application_runner, ApplicationRunner.Scheduler, storage: ApplicationRunner.Storage

config :swarm,
  debug: false

config :logger,
  level: :warning

import_config "#{Mix.env()}.exs"
