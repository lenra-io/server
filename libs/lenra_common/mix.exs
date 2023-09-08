defmodule LenraCommon.MixProject do
  use Mix.Project

  def project do
    [
      app: :lenra_common,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # # Configuration for the OTP application.
  # #
  # # Type `mix help compile.app` for more information.
  # def application do
  #   [
  #     mod: {LenraCommon.Application, []},
  #     extra_applications: [:logger, :runtime_tools, :phoenix]
  #   ]
  # end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.15"},
      {:credo, "~> 1.6.7", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev], runtime: false},
      {:jason, "~> 1.4"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"]
    ]
  end
end
