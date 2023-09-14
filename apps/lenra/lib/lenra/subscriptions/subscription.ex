defmodule Lenra.Subscriptions.Subscription do
  @moduledoc """
    The Subscription schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Ecto.UUID
  alias Lenra.Apps.App

  @derive {Jason.Encoder,
           only: [
             :uuid,
             :start_date,
             :end_date,
             :application_id
           ]}
  schema "subscriptions" do
    field(:uuid, :string, primary_key: true)
    field(:start_date, :date)
    field(:end_date, :date)
    belongs_to(:application, App)

    timestamps()
  end

  def changeset(build, params \\ %{}) do
    build
    |> cast(params, [:start_date, :end_date, :application_id])
    |> validate_required([:start_date, :end_date, :application_id])
    |> unique_constraint(:uuid, name: :subscriptions_uuid_index)
    |> foreign_key_constraint(:application_id)
  end

  def update(build, params) do
    changeset(build, params)
  end

  def new(params) do
    %__MODULE__{
      uuid: UUID.generate()
    }
    |> __MODULE__.changeset(params)
  end
end
