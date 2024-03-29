defmodule Lenra.Apps.App do
  @moduledoc """
    The application schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Accounts.User

  alias Lenra.Apps.{Build, Environment, MainEnv}

  @type t :: %__MODULE__{}

  @hex_regex ~r/[0-9A-Fa-f]{6}/

  @derive {Jason.Encoder, only: [:id, :name, :service_name, :icon, :color, :creator_id]}
  schema "applications" do
    field(:name, :string)
    field(:service_name, Ecto.UUID)
    field(:color, :string)
    field(:icon, :integer)

    # As long as we do not handle repository link read access, we need to redact it
    # and remove it from the JSON response.
    field(:repository, :string, redact: true)
    field(:repository_branch, :string, redact: true)

    belongs_to(:creator, User)
    has_many(:environments, Environment, foreign_key: :application_id)
    has_many(:builds, Build, foreign_key: :application_id)
    has_one(:main_env, MainEnv, foreign_key: :application_id)
    timestamps()
  end

  def changeset(application, params \\ %{}) do
    application
    |> cast(params, [:name, :color, :icon, :repository, :repository_branch])
    |> validate_required([:name, :service_name, :color, :icon, :creator_id])
    |> unique_constraint(:name)
    |> unique_constraint(:service_name)
    |> validate_format(:color, @hex_regex)
    |> validate_length(:name, min: 2, max: 64)
  end

  def new(creator_id, params) do
    %__MODULE__{creator_id: creator_id, service_name: Ecto.UUID.generate()}
    |> __MODULE__.changeset(params)
  end

  def update(app, params) do
    changeset(app, params)
  end
end
