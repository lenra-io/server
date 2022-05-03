# This file is loaded when the server starts. It is used to load all env variable.
# This file is used for staging/test and prod environments.

import Config

config :lenra_web, LenraWeb.Endpoint,
  http: [port: System.fetch_env!("PORT")],
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
  url: [host: {:system, "APP_HOST"}, port: {:system, "PORT"}]

config :lenra, Lenra.Repo,
  username: System.fetch_env!("POSTGRES_USER"),
  password: System.fetch_env!("POSTGRES_PASSWORD"),
  database: System.fetch_env!("POSTGRES_DB"),
  hostname: System.fetch_env!("POSTGRES_HOST")

config :lenra,
  faas_url: System.fetch_env!("FAAS_URL"),
  faas_auth: System.fetch_env!("FAAS_AUTH"),
  faas_registry: System.fetch_env!("FAAS_REGISTRY"),
  runner_secret: System.fetch_env!("RUNNER_SECRET"),
  runner_callback_url: "https://#{System.fetch_env!("APP_HOST")}",
  lenra_env: System.fetch_env!("ENVIRONMENT"),
  gitlab_api_url: System.fetch_env!("GITLAB_API_URL"),
  gitlab_api_token: System.fetch_env!("GITLAB_API_TOKEN"),
  gitlab_project_id: System.fetch_env!("GITLAB_PROJECT_ID"),
  gitlab_ci_ref: "master",
  template_url: System.fetch_env!("TEMPLATE_URL")

# Do not print debug messages in production
config :logger, level: String.to_atom(System.get_env("LOG_LEVEL", "info"))

config :peerage,
  via: Peerage.Via.Dns,
  dns_name: System.fetch_env!("SERVICE_NAME"),
  app_name: "lenra"

config :lenra, Lenra.Mailer, api_key: System.fetch_env!("SENDGRID_API_KEY")

config :lenra, Lenra.Guardian, secret_key: System.fetch_env!("GUARDIAN_SECRET_KEY")

config :lenra, Lenra.AppGuardian, secret_key: System.fetch_env!("GUARDIAN_SECRET_KEY")

# Set the DSN for sentry and the current environment.
# Only production and sentry are used. test env are ignored.
config :sentry,
  dsn: System.fetch_env!("SENTRY_DSN"),
  environment_name: System.fetch_env!("ENVIRONMENT")
