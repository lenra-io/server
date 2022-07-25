defmodule Lenra.Repo do
  use Ecto.Repo,
    otp_app: :lenra,
    adapter: Ecto.Adapters.Postgres

  alias Lenra.Errors.TechnicalError
  alias Lenra.Repo

  require Logger

  def migrate do
    Logger.info("Migrating...")

    path = Application.app_dir(:lenra, "priv/repo/migrations")

    Ecto.Migrator.run(Repo, path, :up, all: true)
  end

  def fetch(query, id, error \\ TechnicalError.error_404_tuple()) do
    case Repo.get(query, id) do
      nil -> error
      res -> {:ok, res}
    end
  end

  def fetch_by(query, args, error \\ TechnicalError.error_404_tuple()) do
    case Repo.get_by(query, args) do
      nil -> error
      res -> {:ok, res}
    end
  end
end
