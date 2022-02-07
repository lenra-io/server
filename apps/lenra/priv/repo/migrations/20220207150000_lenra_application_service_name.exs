defmodule Lenra.Repo.Migrations.LenraApplicationServiceName do
  use Ecto.Migration

  def change do
    alter table(:applications) do
      remove(:service_name, :string)

      add(:service_name, :uuid)
    end

    create(unique_index(:applications, [:service_name]))
  end
end
