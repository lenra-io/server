defmodule Lenra.Apps.UserEnvironmentAccess do
  @moduledoc """
    The user environment access schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Apps.Environment

  alias Lenra.Accounts.User

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder,
           only: [
             :user_id,
             :environment_id
           ]}
  @primary_key {:uuid, Ecto.UUID, autogenerate: true}
  schema "users_environments_access" do
    belongs_to(:user, User)
    belongs_to(:environment, Environment)

    timestamps()
  end

  def changeset(user_env_access, params \\ %{}) do
    user_env_access
    |> cast(params, [:user_id, :environment_id])
    |> validate_required([:environment_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:environment_id)
    |> unique_constraint([:user_id, :environment_id], name: :users_environments_access_pkey)
  end

  def new(env_id, params) do
    %__MODULE__{environment_id: env_id}
    |> __MODULE__.changeset(params)
  end
end
