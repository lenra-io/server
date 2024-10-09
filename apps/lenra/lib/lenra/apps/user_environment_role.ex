defmodule Lenra.Apps.UserEnvironmentRole do
  @moduledoc """
    The user environment role schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Apps.UserEnvironmentAccess

  alias Lenra.Accounts.User

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
    |> foreign_key_constraint(:access_id)
    |> foreign_key_constraint(:creator_id)
    |> unique_constraint([:access_id, :role])
  end

  def new(access_id, params) do
    %__MODULE__{access_id: access_id}
    |> __MODULE__.changeset(params)
  end
end
