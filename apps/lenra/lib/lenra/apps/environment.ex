defmodule Lenra.Apps.Environment do
  @moduledoc """
    The environment schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Accounts.User
  alias Lenra.Apps.{App, Deployment}
  alias Lenra.Apps.UserEnvironmentAccess

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :is_ephemeral,
             :is_public,
             :application_id,
             :creator_id,
             :deployment_id
           ]}
  schema "environments" do
    field(:name, :string)
    field(:is_ephemeral, :boolean)
    field(:is_public, :boolean)
    belongs_to(:application, App)
    belongs_to(:creator, User)
    belongs_to(:deployment, Deployment)
    many_to_many(:shared_with, User, join_through: UserEnvironmentAccess)

    timestamps()
  end

  def changeset(environment, params \\ %{}) do
    environment
    |> cast(params, [:name, :is_ephemeral, :is_public])
    |> validate_required([:name, :is_ephemeral, :is_public, :application_id, :creator_id])
    |> unique_constraint([:name, :application_id])
    |> validate_length(:name, min: 2, max: 32)
    |> foreign_key_constraint(:application_id)
    |> foreign_key_constraint(:creator_id)
  end

  def update(env, params) do
    changeset(env, params)
  end

  def new(application_id, creator_id, deployment_id, params) do
    %__MODULE__{
      application_id: application_id,
      creator_id: creator_id,
      deployment_id: deployment_id
    }
    |> __MODULE__.changeset(params)
  end
end
