defmodule Lenra.MixProject do
  use Mix.Project

  def project do
    [
      app: :lenra,
      version: "0.1.0",
      build_path: "../../_build",
      deps_path: "../../deps",
      config_path: "../../config/config.exs",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      xref: [exclude: [ApplicationRunner]]
    ]
  end

  def application do
    [
      mod: {Lenra.Application, []},
      extra_applications: [:logger, :runtime_tools, :guardian, :bamboo]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_pubsub, "~> 2.0"},
      {:telemetry, "~> 0.4.3", override: true},
      {:ecto_sql, "~> 3.4"},
      {:bamboo, "~> 2.1.0"},
      {:bamboo_smtp, "~> 4.0.1"},
      {:postgrex, "~> 0.15.8"},
      {:jason, "~> 1.2"},
      {:json_diff, "~> 0.1.0"},
      {:guardian, "~> 2.1.1"},
      {:guardian_db, "~> 2.0"},
      {:argon2_elixir, "~> 2.0"},
      {:sentry, "~> 8.0"},
      {:bypass, "~> 2.0", only: :test},
      # {:swarm, "~> 3.0"},
      {:event_queue, git: "https://github.com/lenra-io/event-queue.git", tag: "v1.0.0"},
      {:earmark, "~> 1.4.20", only: [:dev, :test], runtime: false},
      {:libcluster, "~> 3.3"},
      # {:mongodb_driver, "~> 0.9.1"},
      {:application_runner,
      git: "https://github.com/lenra-io/application-runner.git",
       tag: "def695f",
       submodules: true,
       runtime: false},
       {:lenra_common, git: "https://github.com/lenra-io/lenra-common.git", tag: "v2.3.1"}

    ]
  end
end
