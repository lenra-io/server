defmodule Lenra.Apps.OAuthClient do
  @moduledoc """
    The application schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Apps.{Environment}

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder, only: [:id, :oauth_client_id, :environment_id]}
  schema "oauth_clients" do
    field(:oauth_client_id, :string)
    belongs_to(:environment, Environment)
    timestamps()
  end

  def changeset(oauth_client, params \\ %{}) do
    oauth_client
    |> cast(params, [:oauth_client_id])
    |> validate_required([:oauth_client_id, :environment_id])
    |> unique_constraint(:oauth_client_id)
  end

  def new(env_id, oauth_client_id) do
    %__MODULE__{environment_id: env_id, oauth_client_id: oauth_client_id}
    |> __MODULE__.changeset()
  end
end
