defmodule ApplicationRunner.MixProject do
  use Mix.Project

  def project do
    [
      app: :application_runner,
      version: "0.0.0-dev",
      elixir: "~> 1.12",
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [plt_add_apps: [:ex_unit]],
      aliases: [
        test: "test"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ApplicationRunner.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support", "priv/repo"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:ex_component_schema, git: "https://github.com/lenra-io/ex_component_schema", ref: "v1.0.0-beta.6"},
      {:jason, "~> 1.4"},
      {:json_diff, "~> 0.1.3"},
      {:telemetry, "~> 1.2.0"},
      {:swarm, "~> 3.4"},
      {:ecto_sql, "~> 3.9.2"},
      {:postgrex, "~> 0.16.5"},
      {:guardian, "~> 2.3.1"},
      {:phoenix, "~> 1.6.15"},
      {:phoenix_pubsub, "~> 2.1.1"},
      {:finch, "~> 0.14"},
      {:bypass, "~> 2.1", only: :test},
      {:mongodb_driver, "~> 1.2.1"},
      {:crontab, "~> 1.1.13"},
      {:quantum, "~> 3.0"},
      {:query_parser, "~> 1.0.0-beta.27"},
      {:lenra_common, path: "../lenra_common"}
    ]
  end

  defp aliases do
    [
      test: [
        "ecto.drop --repo ApplicationRunner.Repo",
        "ecto.create --quiet",
        "ecto.migrate",
        "test --no-start"
      ],
      "ecto.migrations": [
        "ecto.migrations --migrations-path priv/repo/migrations --migrations-path priv/repo/test_migrations"
      ],
      "ecto.migrate": [
        "ecto.migrate --migrations-path priv/repo/migrations --migrations-path priv/repo/test_migrations"
      ],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"]
    ]
  end
end
