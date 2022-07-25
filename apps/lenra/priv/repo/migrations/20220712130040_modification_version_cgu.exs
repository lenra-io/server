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

    alter table("cgu") do
      modify(:version, :integer, from: :string)
    end

    rename(table("cgu"), :link, to: :path)
  end
end
