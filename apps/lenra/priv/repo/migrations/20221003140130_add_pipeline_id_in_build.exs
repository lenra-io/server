defmodule Lenra.Repo.Migrations.AddPipelineIdInBuild do
  use Ecto.Migration

  def change do
    alter table(:builds) do
      add(:pipeline_id, :integer)
    end
  end
end
