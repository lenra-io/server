defmodule HydraApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :hydra_api,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ory_hydra, "~> 1.2"},
      {:plug_cowboy, "~> 2.0"}
    ]
  end
end
