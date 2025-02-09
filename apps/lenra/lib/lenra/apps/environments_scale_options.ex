defmodule Lenra.Apps.EnvironmentScaleOptions do
  @moduledoc """
    The environment scale options.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Apps.Environment

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder,
           only: [
             :environment_id,
             :min,
             :max
           ]}
  schema "environments_scale_options" do
    field(:min, :integer)
    field(:max, :integer)
    belongs_to(:environment, Environment)

    timestamps()
  end

  def changeset(scale_options, params \\ %{}) do
    scale_options
    |> cast(params, [:min, :max])
    |> validate_required([:environment_id])
    |> foreign_key_constraint(:environment_id)
    |> unique_constraint([:environment_id], name: :environment_id_unique_index)
  end

  def new(env_id, params) do
    %__MODULE__{environment_id: env_id}
    |> __MODULE__.changeset(params)
  end
end
