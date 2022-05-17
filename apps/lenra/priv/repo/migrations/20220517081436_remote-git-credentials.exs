defmodule Lenra.Repo.Migrations.RemoteGitCredentials do
  use Ecto.Migration

  def change do
    create table(:repositories) do
      add(:application_id, references(:applications, on_delete: :delete_all))
      add(:url, :string, null: false)
      add(:branch, :string)
      add(:username, :string)
      add(:token, :string)
      timestamps()
    end

    execute("INSERT INTO repositories (application_id, url, branch) SELECT id, repository, repository_branch FROM applications", "")

    alter table(:applications) do
      remove(:repository)
      remove(:repository_branch)
    end
  end
end
