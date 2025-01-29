defmodule Lenra.Apps.UserEnvironmentRole do
  @moduledoc """
    The user environment role schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Apps.UserEnvironmentAccess

  alias Lenra.Accounts.User

  @role_regex ~r/^[a-zA-Z0-9][a-zA-Z0-9+@:.#_-]{1,49}$/
  @reserved_roles ["owner", "user"]

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder,
           only: [
             :access_id,
             :creator_id
           ]}
  schema "users_environments_roles" do
    belongs_to(:access, UserEnvironmentAccess)
    field(:role, :string)
    belongs_to(:creator, User)

    timestamps()
  end

  def changeset(user_env_role, params \\ %{}) do
    user_env_role
    |> cast(params, [:creator_id, :access_id, :role])
    |> validate_required([:access_id, :role])
    |> validate_format(:role, @role_regex)
    |> validate_exclusion(:role, @reserved_roles)
    |> foreign_key_constraint(:access_id)
    |> foreign_key_constraint(:creator_id)
    |> unique_constraint([:access_id, :role], error_key: :role)
  end

  def new(access_id, params) do
    %__MODULE__{access_id: access_id}
    |> __MODULE__.changeset(params)
  end
end
