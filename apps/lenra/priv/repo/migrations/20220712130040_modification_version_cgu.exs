defmodule Lenra.Repo.Migrations.ModificationVersionCgu do
  use Ecto.Migration

  def change do
    execute(
      """
       alter table cgu alter column version type integer using (version::integer)
      """,
      """
       alter table cgu alter column version type character varying(255);
      """
    )

    drop(unique_index(:cgu, [:link]))
    rename(table("cgu"), :link, to: :path)
    create(unique_index(:cgu, [:path]))
  end
end
