defmodule :"Elixir.Lenra.Repo.Migrations.Remote-git-credentials" do
  use Ecto.Migration

  def change do
    create table(:repositories) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:url, :string, null: false)
      add(:branch, :string)
      add(:username, :string)
      add(:token, :string)
      timestamps()
    end

    execute("INSERT INTO repositories (user_id, url, branch) SELECT id, repository, repository_branch FROM users", "")

    alter table(:users) do
      drop(:repository)
      drop(:repository_branch)
    end
  end
end
