defmodule Lenra.Apps.EnvSecret do
  @moduledoc """
    The Environment's Secret schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Apps.{Environment}

  @type t :: %__MODULE__{}

  @hex_regex ~r/[0-9A-Fa-f]{6}/

  @derive {Jason.Encoder, only: [:id, :environment_id, :key, :value, :is_obfuscated]}
  schema "env_secrets" do
    field(:key, :string)
    field(:value,:string)
    field(:is_obfuscated, :boolean)
    belongs_to(:environment, Environment)
    timestamps()
  end

  def changeset(env_secret, params \\ %{}) do
    env_secret
    |> cast(params, [:key, :value, :is_obfuscated])
    |> validate_required([:key, :value])
    |> unique_constraint([:key, :environment_id])
    |> validate_length(:key, min: 2, max: 64)
  end

  def new(env_id, key, params) do
    %__MODULE__{environment_id: env_id, key: key}
    |> __MODULE__.changeset(params)
  end

  def update(secret, params) do
    secret
    |> __MODULE__.changeset(params)
  end
end
