defmodule Lenra.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [
        plt_add_deps: :transitive,
        plt_file: {:no_warn, ".plts/dialyzer.plt"},
        plt_add_apps: [:mix]
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      # releases
      releases: [
        lenra: [
          applications: [
            lenra_web: :permanent,
            identity_web: :permanent,
            runtime_tools: :permanent
          ],
          include_executables_for: [:unix]
        ]
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:credo, "~> 1.7.2", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev], runtime: false},
      {:sobelow, "~> 0.11.1", only: :dev},
      {:excoveralls, "~> 0.15.2", only: :test},
      {:benchee, "~> 1.1", only: :dev}
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
      start: ["phx.server"],
      setup: ["deps.get", "ecto.setup", "lenra.seeds"],
      "ecto.setup": [
        "ecto.create",
        "ecto.migrate --migrations-path apps/lenra/priv/repo/migrations --migrations-path libs/application_runner/priv/repo/migrations",
        "run apps/lenra/priv/repo/seeds.exs"
      ],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "lenra.seeds": ["run apps/lenra/priv/repo/seeds.exs"],
      test: [
        "ecto.drop --quiet",
        "ecto.create --quiet",
        "ecto.migrate --migrations-path apps/lenra/priv/repo/migrations --migrations-path libs/application_runner/priv/repo/migrations",
        "test"
      ]
    ]
  end
end
