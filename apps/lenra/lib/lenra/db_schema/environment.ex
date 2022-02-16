defmodule Lenra.Environment do
  @moduledoc """
    The environment schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.{
    Build,
    Environment,
    LenraApplication,
    User
  }

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :is_ephemeral,
             :application_id,
             :creator_id,
             :deployed_build_id,
             :shared_with
           ]}
  schema "environments" do
    field(:name, :string)
    field(:is_ephemeral, :boolean)
    belongs_to(:application, LenraApplication)
    belongs_to(:creator, User)
    belongs_to(:deployed_build, Build)
    many_to_many(:shared_with, User, join_through: "users_environments_access")
    timestamps()
  end

  def changeset(environment, params \\ %{}) do
    environment
    |> cast(params, [:name, :is_ephemeral])
    |> validate_required([:name, :is_ephemeral, :application_id, :creator_id])
    |> unique_constraint([:name, :application_id])
    |> validate_length(:name, min: 2, max: 32)
    |> foreign_key_constraint(:application_id)
    |> foreign_key_constraint(:creator_id)
  end

  def update(env, params) do
    changeset(env, params)
  end

  def new(application_id, creator_id, deployed_build_id, params) do
    %Environment{
      application_id: application_id,
      creator_id: creator_id,
      deployed_build_id: deployed_build_id
    }
    |> Environment.changeset(params)
  end
end
