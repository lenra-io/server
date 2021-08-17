defmodule Lenra.Datastore do
  @moduledoc """
    The datastore schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.{User, LenraApplication, Datastore}

  schema "datastores" do
    belongs_to(:user, User)
    belongs_to(:application, LenraApplication)
    field(:data, :map)
    timestamps()
  end

  def changeset(datastore, params \\ %{}) do
    datastore
    |> cast(params, [:data])
    |> validate_required([:data])
    |> unique_constraint(:user_application_unique, name: :datastores_user_id_application_id_index)
  end

  def new(user_id, application_id, data) do
    %Datastore{user_id: user_id, application_id: application_id}
    |> Datastore.changeset(%{"data" => data})
  end
end
