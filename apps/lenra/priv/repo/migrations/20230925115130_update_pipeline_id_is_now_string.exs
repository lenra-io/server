defmodule Lenra.Repo.Migrations.UpdatePipelineIdIsNowString do
  use Ecto.Migration

  def change do
    alter table(:builds) do
      modify(:pipeline_id, :string, from: {:integer})
    end
  end
end
