defmodule ApplicationRunner.Contract.User do
  @moduledoc """
    The user "contract" schema.
        This give ApplicationRunner an interface to match with the "real" user for both the Devtool and the Lenra server
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias ApplicationRunner.Crons.Cron
  alias ApplicationRunner.Monitor.SessionMeasurement
  alias ApplicationRunner.Webhooks.Webhook

  @table_name Application.compile_env!(:application_runner, :lenra_user_table)
  schema @table_name do
    field(:email, :string)
    has_many(:webhooks, Webhook, foreign_key: :uuid)
    has_many(:crons, Cron, foreign_key: :id)
    has_many(:session_measurements, SessionMeasurement)

    timestamps()
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:email])
    |> validate_required([:email])
  end

  def embed(user) do
    user_map =
      if is_struct(user) do
        user |> Map.from_struct()
      else
        user
      end

    changeset =
      %__MODULE__{}
      |> cast(user_map, [:id, :email, :inserted_at, :updated_at])
      |> validate_required([:id, :email, :inserted_at, :updated_at])
      |> unique_constraint(:email)
      |> unique_constraint(:id)

    if changeset.valid? do
      Ecto.Changeset.apply_changes(changeset)
    else
      changeset
    end
  end

  def new(params) do
    %__MODULE__{}
    |> __MODULE__.changeset(params)
  end
end
