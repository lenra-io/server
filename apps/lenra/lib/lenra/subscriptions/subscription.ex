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
             :start_date,
             :end_date,
             :application_id
           ]}
  schema "subscriptions" do
    field(:start_date, :date)
    field(:end_date, :date)
    belongs_to(:application, App)

    timestamps()
  end

  def changeset(build, params \\ %{}) do
    build
    |> cast(params, [:start_date, :end_date, :application_id])
    |> validate_required([:start_date, :end_date, :application_id])
    |> foreign_key_constraint(:application_id)
  end

  def update(build, params) do
    changeset(build, params)
  end

  def new(params) do
    %__MODULE__{}
    |> __MODULE__.changeset(params)
  end
end
