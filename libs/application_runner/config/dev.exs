import Config

config :application_runner, ApplicationRunner.Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  database: System.get_env("POSTGRES_DB", "lenra_dev"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
