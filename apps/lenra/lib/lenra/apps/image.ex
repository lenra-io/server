defmodule Lenra.Apps.Image do
  @moduledoc """
    The image schema.
  """

  use Lenra.Schema
  import Ecto.Changeset
  alias Lenra.Accounts.User

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder,
           only: [
             :data,
             :type,
             :creator_id
           ]}
  schema "images" do
    field(:data, :binary)
    field(:type, :string)
    belongs_to(:creator, User)

    timestamps()
  end

  def changeset(image, params \\ %{}) do
    image
    |> cast(params, [:data, :type])
    |> validate_required([:data, :type, :creator_id])
    |> foreign_key_constraint(:creator_id)
  end

  def new(creator_id, params) do
    %__MODULE__{
      creator_id: creator_id
    }
    |> __MODULE__.changeset(params)
  end
end
