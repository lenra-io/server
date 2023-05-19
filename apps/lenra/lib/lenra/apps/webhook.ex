defmodule Lenra.Apps.Webhook do
  @moduledoc """
    The webhook schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.Accounts.User
  alias Lenra.Apps.{Environment, Webhook}

  @derive {Jason.Encoder, only: [:uuid, :action, :props, :environment_id, :user_id]}
  @primary_key {:uuid, Ecto.UUID, autogenerate: true}
  schema "webhooks" do
    belongs_to(:environment, Environment)
    belongs_to(:user, User)

    field(:action, :string)
    field(:props, :map)

    timestamps()
  end

  def changeset(webhook, params \\ %{}) do
    webhook
    |> cast(params, [:action, :props, :user_id])
    |> validate_required([:environment_id, :action])
    |> foreign_key_constraint(:environment_id)
    |> foreign_key_constraint(:user_id)
  end

  def embed(webhook) do
    webhook_map =
      if is_struct(webhook) do
        webhook |> Map.from_struct()
      else
        webhook
      end

    changeset =
      %__MODULE__{}
      |> cast(webhook_map, [:uuid, :action, :props, :user_id, :environment_id, :inserted_at, :updated_at])
      |> validate_required([:environment_id, :action])
      |> foreign_key_constraint(:environment_id)
      |> foreign_key_constraint(:user_id)

    if changeset.valid? do
      Ecto.Changeset.apply_changes(changeset)
    else
      changeset
    end
  end

  def new(env_id, params) do
    %Webhook{environment_id: env_id}
    |> Webhook.changeset(params)
  end
end
