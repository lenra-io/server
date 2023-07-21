defmodule Lenra.Apps.OAuth2Client do
  @moduledoc """
    The application schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Apps.{Environment}

  @type t :: %__MODULE__{}

  @redirect_uris_regex ~r/^https?:\/\/\w+(\.\w+)*(:[0-9]+)?\/?(\/[.\w]*)*$/
  @allowed_origins_regex ~r/^https?:\/\/\w+(\.\w+)*(:[0-9]+)?$/
  @allowed_scopes ["profile", "store", "resources", "manage:account", "manage:apps"]

  @derive {Jason.Encoder, only: [:oauth_client_id, :environment_id, :name, :scopes, :redirect_uris, :allowed_origins]}
  schema "oauth_clients" do
    field(:oauth_client_id, :string)
    belongs_to(:environment, Environment)
    timestamps()

    # Fields for hydra only (reuse the same scheme)
    field(:name, :string, virtual: true)
    field(:scopes, {:array, :string}, virtual: true)
    field(:redirect_uris, {:array, :string}, virtual: true)
    field(:allowed_origins, {:array, :string}, virtual: true)
  end

  defp changeset_db(oauth_client, params) do
    oauth_client
    |> cast(params, [:oauth_client_id])
    |> validate_required([:oauth_client_id, :environment_id])
    |> unique_constraint(:oauth_client_id)
  end

  def update_for_db(oauth_client, oauth_client_id) do
    oauth_client
    |> changeset_db(%{"oauth_client_id" => oauth_client_id})
  end

  def changeset_hydra(oauth_client, params) do
    oauth_client
    |> cast(params, [:name, :scopes, :redirect_uris, :allowed_origins, :environment_id])
    |> validate_required([:environment_id])
    |> validate_hydra()
  end

  defp changeset_update_hydra(oauth_client, params) do
    oauth_client
    |> cast(params, [:name, :scopes, :redirect_uris, :allowed_origins])
    |> validate_hydra()
  end

  defp validate_hydra(changeset) do
    changeset
    |> validate_required([:name, :scopes, :redirect_uris, :allowed_origins])
    |> validate_length(:name, min: 3, max: 64)
    |> validate_subset(:scopes, @allowed_scopes)
    |> validate_list_regex(:redirect_uris, @redirect_uris_regex)
    |> validate_list_regex(:allowed_origins, @allowed_origins_regex)
  end

  defp validate_list_regex(changeset, field, regex) do
    validate_change(changeset, field, fn _field, uris ->
      Enum.reduce_while(uris, [], fn uri, _validated ->
        if Regex.match?(regex, uri) do
          {:cont, []}
        else
          {:halt, [{field, {"is invalid format", value: uri, format: regex}}]}
        end
      end)
    end)
  end

  def new(params) do
    %__MODULE__{}
    |> changeset_hydra(params)
  end

  def update(oauth2_client, params) do
    oauth2_client
    |> changeset_update_hydra(params)
  end
end
