defmodule Lenra.Apps.Deployment do
  @moduledoc """
    The deployment schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Apps.{
    App,
    Build,
    Environment
  }

  alias Lenra.Accounts.User

  @derive {Jason.Encoder,
           only: [:id, :application_id, :environment_id, :build_id, :publisher_id, :status, :inserted_at]}

  schema "deployments" do
    field(:status, Ecto.Enum, values: [:created, :waitingForBuild, :waitingForAppReady, :failure, :success])
    belongs_to(:application, App)
    belongs_to(:environment, Environment)
    belongs_to(:build, Build)
    belongs_to(:publisher, User)

    timestamps()
  end

  def changeset(deployment, params \\ %{}) do
    deployment
    |> cast(params, [])
    |> validate_required([:environment_id, :build_id, :publisher_id, :application_id, :status])
    |> unique_constraint([:environment_id, :build_id])
    |> foreign_key_constraint(:environment_id)
    |> foreign_key_constraint(:build_id)
    |> foreign_key_constraint(:publisher_id)
  end

  def new(application_id, environment_id, build_id, user_id, params) do
    %__MODULE__{
      status: :waitingForBuild,
      application_id: application_id,
      environment_id: environment_id,
      build_id: build_id,
      publisher_id: user_id
    }
    |> __MODULE__.changeset(params)
  end
end
