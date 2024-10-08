# This is the dev config, loaded only on local on compile time so the secrets are not important.
# DO NOT USE THESE SECRET ON PRODUCTION !

import Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with esbuild to bundle .js and .css sources.
config :identity_web, IdentityWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("IDENTITY_WEB_PORT", "4010"))],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "1u72jPqMMkDMK7rgr2vr+YWkhhv84cr3pSNEGZJC7LeIJFP+FW9zXeG28q7X7Jfw",
  watchers: [
    # Start the esbuild watcher by calling Esbuild.install_and_run(:default, args)
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ]

# Watch static and templates for browser reloading.
config :identity_web, IdentityWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/identity_web/(live|views)/.*(ex)$",
      ~r"lib/identity_web/templates/.*(eex)$"
    ]
  ]

# Configure your database
config :lenra, Lenra.Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  database: System.get_env("POSTGRES_DB", "lenra_dev"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :application_runner, ApplicationRunner.Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  database: System.get_env("POSTGRES_DB", "lenra_dev"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :lenra_web, LenraWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))],
  secret_key_base: "FuEn07fjnCLaC53BiDoBagPYdsv/S65QTfxWgusKP1BA5NiaFzXGYMHLZ6JAYxt1",
  debug_errors: false,
  code_reloader: true,
  watchers: []

config :lenra_web,
  public_api_url: "http://localhost:#{String.to_integer(System.get_env("PORT", "4000"))}"

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "$time [$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :lenra,
  faas_url: System.get_env("FAAS_URL", "https://openfaas-dev.lenra.me"),
  faas_auth: System.get_env("FAAS_AUTH", "Basic YWRtaW46Z0Q4VjNHR1YxeUpS"),
  faas_registry: System.get_env("FAAS_REGISTRY", "registry.gitlab.com/lenra/platform/lenra-ci"),
  runner_callback_url: System.get_env("LOCAL_TUNNEL_URL"),
  lenra_env: "dev",
  gitlab_api_url: System.get_env("GITLAB_API_URL", "https://gitlab.com/api/v4"),
  gitlab_api_token: System.get_env("GITLAB_API_TOKEN", "Zuz-dZc834q3CtU-bnX5"),
  gitlab_project_id: System.get_env("GITLAB_PROJECT_ID", "26231009"),
  gitlab_ci_ref: System.get_env("GITLAB_CI_REF", "master"),
  runner_secret:
    System.get_env(
      "RUNNER_SECRET",
      "sZWshq6h0RNO9T1GgUnzLmPpDkSkDAoukmd30mTuwQAGIHYIIVdl7VD2h305"
    ),
  lenra_email: System.get_env("LENRA_EMAIL", "contact@lenra.io"),
  lenra_app_url: System.get_env("LENRA_APP_URL", "https://localhost:10000"),
  pipeline_runner: System.get_env("PIPELINE_RUNNER", "GitLab"),
  kubernetes_api_url: System.get_env("KUBERNETES_API_URL"),
  kubernetes_api_cert: System.get_env("KUBERNETES_API_CERT"),
  kubernetes_api_token: System.get_env("KUBERNETES_API_TOKEN", ""),
  kubernetes_build_namespace: System.get_env("KUBERNETES_BUILD_NAMESPACE", "lenra_build"),
  kubernetes_build_scripts: System.get_env("KUBERNETES_BUILD_SCRIPTS", "lenra_build"),
  kubernetes_build_secret: System.get_env("KUBERNETES_BUILD_SECRET", "lenra_build"),
  stripe_coupon: System.get_env("STRIPE_COUPON"),
  stripe_secret: System.get_env("STRIPE_SECRET"),
  webhook_secret: System.get_env("WEBHOOK_SECRET")

config :application_runner,
  faas_secrets: ["gitlab-registry"],
  faas_request_cpu: System.get_env("FAAS_REQUEST_CPU", "50m"),
  faas_request_memory: System.get_env("FAAS_REQUEST_MEMORY", "128Mi"),
  faas_limit_cpu: System.get_env("FAAS_LIMIT_CPU", "100m"),
  faas_limit_memory: System.get_env("FAAS_LIMIT_MEMORY", "256Mi")

config :stripity_stripe, api_key: System.get_env("STRIPE_SECRET")

config :lenra, Lenra.Mailer, sandbox: true, api_key: System.get_env("SENDGRID_API_KEY")

config :cors_plug,
  origin: System.get_env("ALLOWED_CLIENT_ORIGINS", "http://localhost:10000") |> String.split(","),
  methods: ["GET", "POST", "PUT", "PATCH", "OPTION", "DELETE"]

config :hydra_api,
  hydra_url: System.get_env("HYDRA_URL", "http://localhost:4445")
