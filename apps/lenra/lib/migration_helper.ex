defmodule Lenra.MigrationHelper do
  @moduledoc """
    `Lenra.MigrationHelper` give some useful function like `migrate/0` or `rollback/2` the repositories.
  """

  @app :lenra

  def migrate do
    for repo <- repos() do
      {:ok, _fun_return, _apps} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    {:ok, _fun_return, _apps} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
