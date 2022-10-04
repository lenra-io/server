defmodule Lenra.Apps.Build do
  @moduledoc """
    The build schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Accounts.User
  alias Lenra.Apps.{App, Build}

  @derive {Jason.Encoder,
           only: [
             :id,
             :commit_hash,
             :build_number,
             :status,
             :creator_id,
             :application_id,
             :inserted_at
           ]}
  schema "builds" do
    field(:commit_hash, :string)
    field(:build_number, :integer)
    field(:status, Ecto.Enum, values: [:pending, :failure, :success])
    belongs_to(:creator, User)
    belongs_to(:application, App)

    timestamps()
  end

  def changeset(build, params \\ %{}) do
    build
    |> cast(params, [:commit_hash, :status])
    |> validate_required([:build_number, :status, :creator_id, :application_id])
    |> validate_inclusion(:status, Ecto.Enum.values(Build, :status))
    |> foreign_key_constraint(:creator_id)
    |> foreign_key_constraint(:application_id)
  end

  def update(build, params) do
    changeset(build, params)
  end

  def new(creator_id, application_id, build_number, params) do
    %__MODULE__{
      creator_id: creator_id,
      application_id: application_id,
      build_number: build_number,
      status: :pending
    }
    |> __MODULE__.changeset(params)
  end
end
