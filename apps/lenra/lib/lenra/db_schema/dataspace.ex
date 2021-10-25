defmodule Lenra.Dataspace do
  @moduledoc """
    The datastore schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.{Dataspace, LenraApplication, Datastore}

  schema "dataspaces" do
    belongs_to(:application, LenraApplication)
    has_many(:datastores, Datastore)
    field(:name, :string)
    field(:schema, :map)

    timestamps()
  end

  def changeset(dataspace, params \\ %{}) do
    dataspace
    |> cast(params, [:schema])
    |> validate_required([:name])
    |> foreign_key_constraint(:owner_id)
    |> foreign_key_constraint(:application_id)
  end

  def new(application_id, name, params \\ %{}) do
    %Dataspace{application_id: application_id, name: name}
    |> Dataspace.changeset(params)
  end
end
