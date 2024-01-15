defmodule Lenra.Apps.Logo do
  @moduledoc """
    The logo schema.
  """

  use Lenra.Schema
  import Ecto.Changeset
  alias Lenra.Apps.App
  alias Lenra.Apps.Environment
  alias Lenra.Apps.Image

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder,
           only: [
             :application_id,
             :environment_id,
             :image_id
           ]}
  schema "logos" do
    belongs_to(:application, App)
    belongs_to(:environment, Environment)
    belongs_to(:image, Image)

    timestamps()
  end

  def changeset(logo, params) do
    logo
    |> cast(params, [:image_id])
    |> validate_required([:application_id, :image_id])
    |> foreign_key_constraint(:application_id)
    |> foreign_key_constraint(:environment_id)
    |> foreign_key_constraint(:image_id)
  end

  def new(application_id, environment_id, params \\ %{}) do
    %__MODULE__{
      application_id: application_id,
      environment_id: environment_id
    }
    |> __MODULE__.changeset(params)
  end
end
