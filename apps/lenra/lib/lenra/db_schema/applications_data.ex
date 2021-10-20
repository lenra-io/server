defmodule Lenra.ApplicationsData do
  @moduledoc """
    The applications data shema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.{ApplicationsUsersData, ApplicationsData, LenraApplication}

  schema "applications_data" do
    field(:json_data, {:map, :string})
    has_many(:applications_user_data, ApplicationsUsersData)
    belongs_to(:application, LenraApplication)

    timestamps()
  end

  def changeset(application_data, params \\ %{}) do
    application_data
    |> cast(params, [:json_data])
    |> validate_required([:json_data, :application_id])
    |> foreign_key_constraint(:application_id)
  end

  def new(application, data) do
    %ApplicationsData{application_id: application.id}
    |> changeset(data)
  end
end
