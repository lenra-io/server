defmodule Lenra.MigrationHelper do
  @moduledoc """
    `Lenra.MigrationHelper` give some useful function like `migrate/0` or `rollback/2` the repositories.
  """

  @app :lenra

  def migrate do
    for repo <- repos() do
      {:ok, _fun_return, _apps} =
        Ecto.Migrator.with_repo(
          repo,
          &Ecto.Migrator.run(&1, all_migration_paths(), :up, all: true)
        )
    end
  end

  def all_migration_paths do
    [
      Application.app_dir(:lenra, "priv/repo/migrations"),
      Application.app_dir(:application_runner, "priv/repo/migrations")
    ]
  end

  def rollback(repo, _version) do
    {:ok, _fun_return, _apps} =
      Ecto.Migrator.with_repo(
        repo,
        &Ecto.Migrator.run(&1, all_migration_paths(), :down, all: true)
      )
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
