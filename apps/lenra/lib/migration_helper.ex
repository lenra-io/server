defmodule Lenra.MigrationHelper do
  @moduledoc """
    `Lenra.MigrationHelper` give some useful function like `migrate/0` or `rollback/2` the repositories.
  """

  @app :lenra

  def migrate do
    Ecto.Migrator.migrations(
      Lenra.Repo,
      [
        Ecto.Migrator.migrations_path(Lenra.Repo, "apps/lenra/priv/repo/migrations"),
        Ecto.Migrator.migrations_path(Lenra.Repo, "deps/application_runner/priv/repo/migrations")
      ]
    )
  end

  def rollback(repo, version) do
    {:ok, _fun_return, _apps} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  # defp repos do
  #   Application.load(@app)
  #   Application.fetch_env!(@app, :ecto_repos)
  # end
end
