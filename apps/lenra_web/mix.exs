defmodule LenraWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :lenra_web,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {LenraWeb.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.5.9"},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:plug_cowboy, "~> 2.0"},
      {:phoenix_ecto, "~> 4.1"},
      {:sentry, "~> 8.0"},
      {:lenra, in_umbrella: true},
      {:cors_plug, "~> 3.0", only: :dev, runtime: false},
      {:bouncer, git: "https://github.com/lenra-io/bouncer.git", tag: "v1.0.0"},
      private_git(
        name: :application_runner,
        host: "github.com",
        project: "lenra-io/application-runner.git",
        tag: "v1.0.0-data.19",
        credentials: "shiipou:#{System.get_env("GH_PERSONNAL_TOKEN")}"
      )
    ]
  end
end
