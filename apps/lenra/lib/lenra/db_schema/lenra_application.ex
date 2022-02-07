defmodule Lenra.LenraApplication do
  @moduledoc """
    The application schema.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Lenra.{User, Datastore, LenraApplication, Environment, Build, ApplicationMainEnv, AppUserSession}

  @hex_regex ~r/[0-9A-Fa-f]{6}/

  @derive {Jason.Encoder, only: [:id, :name, :service_name, :icon, :color, :creator_id, :repository]}
  schema "applications" do
    field(:name, :string)
    field(:service_name, Ecto.UUID)
    field(:color, :string)
    field(:icon, :integer)
    field(:repository, :string)

    belongs_to(:creator, User)
    has_many(:datastores, Datastore, foreign_key: :application_id)
    has_many(:environments, Environment, foreign_key: :application_id)
    has_many(:builds, Build, foreign_key: :application_id)
    has_one(:main_env, ApplicationMainEnv, foreign_key: :application_id)
    has_many(:app_user_session, AppUserSession, foreign_key: :application_id)
    timestamps()
  end

  def changeset(application, params \\ %{}) do
    application
    |> cast(params, [:name, :service_name, :color, :icon, :repository])
    |> validate_required([:name, :service_name, :color, :icon, :creator_id])
    |> unique_constraint(:name)
    |> unique_constraint(:service_name)
    |> validate_format(:color, @hex_regex)
    |> validate_length(:name, min: 2, max: 64)
  end

  def new(creator_id, params) do
    %LenraApplication{creator_id: creator_id, service_name: Ecto.UUID.generate()}
    |> changeset(params)
  end

  def update(app, params) do
    app
    |> changeset(params)
  end
end
