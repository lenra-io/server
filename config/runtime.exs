# This file is loaded when the server starts. It is used to load all env variable.
# This file is used for staging/test and prod environments.

import Config

if config_env() == :prod do
  config :lenra_web, LenraWeb.Endpoint,
    http: [port: System.fetch_env!("PORT")],
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
    url: [host: System.fetch_env!("API_ENDPOINT"), port: System.fetch_env!("PORT")]

  config :lenra_web,
    public_api_url: System.fetch_env!("LENRA_SERVER_URL")

  config :identity_web, IdentityWeb.Endpoint,
    http: [port: System.get_env("IDENTITY_WEB_PORT", "4010")],
    secret_key_base: System.fetch_env!("IDENTITY_WEB_SECRET_KEY_BASE"),
    url: [
      host: System.fetch_env!("IDENTITY_WEB_ENDPOINT"),
      port: System.get_env("IDENTITY_WEB_PORT", "4010")
    ]

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
    runner_callback_url:
      System.get_env(
        "PIPELINE_CALLBACK_URL",
        "http://#{System.fetch_env!("API_ENDPOINT")}:#{System.fetch_env!("PORT")}"
      ),
    lenra_env: System.fetch_env!("ENVIRONMENT"),
    gitlab_api_url: System.fetch_env!("GITLAB_API_URL"),
    gitlab_api_token: System.fetch_env!("GITLAB_API_TOKEN"),
    gitlab_project_id: System.fetch_env!("GITLAB_PROJECT_ID"),
    gitlab_ci_ref: "master",
    lenra_email: System.fetch_env!("LENRA_EMAIL"),
    lenra_app_url: System.fetch_env!("LENRA_APP_URL"),
    pipeline_runner: System.get_env("PIPELINE_RUNNER", "gitlab"),
    kubernetes_api_url: System.get_env("KUBERNETES_API_URL", "https://kubernetes.default.svc.cluster.local"),
    kubernetes_api_cert:
      System.get_env(
        "KUBERNETES_API_CERT",
        "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
      ),
    kubernetes_api_token:
      System.get_env("KUBERNETES_API_TOKEN") ||
        System.get_env(
          "KUBERNETES_API_TOKEN_PATH",
          "/var/run/secrets/kubernetes.io/serviceaccount/token"
        )
        |> File.read!()
        |> String.trim(),
    kubernetes_build_namespace: System.get_env("KUBERNETES_BUILD_NAMESPACE", "lenra-build"),
    kubernetes_build_scripts: System.get_env("KUBERNETES_BUILD_SCRIPTS", "lenra-build-scripts"),
    kubernetes_build_secret: System.get_env("KUBERNETES_BUILD_SECRET", "lenra-build-secret"),
    stripe_coupon: System.get_env("STRIPE_COUPON"),
    stripe_secret: System.get_env("STRIPE_SECRET"),
    webhook_secret: System.get_env("WEBHOOK_SECRET")

  config :application_runner,
    internal_api_url: "http://" <> System.fetch_env!("API_ENDPOINT") <> ":" <> System.fetch_env!("PORT"),
    faas_url: System.fetch_env!("FAAS_URL"),
    faas_auth: System.fetch_env!("FAAS_AUTH"),
    faas_registry: System.fetch_env!("FAAS_REGISTRY"),
    gitlab_api_url: System.fetch_env!("GITLAB_API_URL"),
    listeners_timeout: String.to_integer(System.fetch_env!("LISTENERS_TIMEOUT")),
    view_timeout: String.to_integer(System.fetch_env!("VIEW_TIMEOUT")),
    manifest_timeout: String.to_integer(System.fetch_env!("MANIFEST_TIMEOUT")),
    env: System.fetch_env!("ENVIRONMENT"),
    scale_to_zero: System.get_env("SCALE_TO_ZERO", "true") == "true",
    faas_request_cpu: System.get_env("FAAS_REQUEST_CPU", "50m"),
    faas_request_memory: System.get_env("FAAS_REQUEST_MEMORY", "128Mi"),
    faas_limit_cpu: System.get_env("FAAS_LIMIT_CPU", "100m"),
    faas_limit_memory: System.get_env("FAAS_LIMIT_MEMORY", "256Mi")

  config :stripity_stripe, api_key: System.get_env("STRIPE_SECRET")

  config :application_runner, ApplicationRunner.Repo,
    username: System.fetch_env!("POSTGRES_USER"),
    password: System.fetch_env!("POSTGRES_PASSWORD"),
    database: System.fetch_env!("POSTGRES_DB"),
    hostname: System.fetch_env!("POSTGRES_HOST"),
    show_sensitive_data_on_connection_error: true,
    pool_size: 10

  config :application_runner, :mongo,
    hostname: System.fetch_env!("MONGO_HOSTNAME"),
    port: System.get_env("MONGO_PORT", "27017"),
    username: System.get_env("MONGO_USERNAME"),
    password: System.get_env("MONGO_PASSWORD"),
    ssl: System.get_env("MONGO_SSL", "false"),
    auth_source: System.get_env("MONGO_AUTH_SOURCE")

  # Do not print debug messages in production
  config :logger, level: String.to_atom(System.get_env("LOG_LEVEL", "info"))

  config :libcluster,
    topologies: [
      lenra: [
        # The selected clustering strategy. Required.
        strategy: Elixir.Cluster.Strategy.Kubernetes.DNS,
        # Configuration for the provided strategy. Optional.
        config: [
          service: System.fetch_env!("SERVICE_NAME"),
          application_name: "lenra",
          polling_interval: 10_000
        ]
      ]
    ]

  config :lenra, Lenra.Mailer, api_key: System.fetch_env!("SENDGRID_API_KEY")

  config :lenra_web, LenraWeb.Guardian, secret_key: System.fetch_env!("GUARDIAN_SECRET_KEY")

  config :lenra_web, LenraWeb.AppGuardian, secret_key: System.fetch_env!("GUARDIAN_SECRET_KEY")

  # Set the DSN for sentry and the current environment.
  # Only production and sentry are used. test env are ignored.
  config :sentry,
    dsn: System.fetch_env!("SENTRY_DSN"),
    environment_name: System.fetch_env!("ENVIRONMENT")

  config :hydra_api,
    hydra_url: System.fetch_env!("HYDRA_URL")
end
