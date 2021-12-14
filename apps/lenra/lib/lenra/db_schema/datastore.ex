defmodule Lenra.Datastore do
  @moduledoc """
    The datastore schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.{Datastore, Data, LenraApplication}

  schema "datastores" do
    # belongs_to(:owner, User)
    # belongs_to(:dataspace, Dataspace)
    has_one(:data, Data)
    belongs_to(:application, LenraApplication)
    field(:name, :string)
    timestamps()
  end

  def changeset(datastore, params \\ %{}) do
    datastore
    |> cast(params, [])
    |> validate_required([:name, :application_id])
    |> foreign_key_constraint(:application_id)
  end

  def new(application_id, name) do
    %Datastore{application_id: application_id, name: name}
    |> Datastore.changeset()
  end
end
