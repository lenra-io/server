defmodule Lenra.Repo.Migrations.AddRepositoryBranch do
  use Ecto.Migration

  def change do
    alter table(:applications) do
      add(:repository_branch, :string)
    end
  end
end
