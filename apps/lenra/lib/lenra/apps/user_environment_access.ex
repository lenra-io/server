defmodule Lenra.Apps.UserEnvironmentAccess do
  @moduledoc """
    The user environment access schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Apps.Environment
  alias Lenra.Apps.UserEnvironmentRole
  alias Lenra.Accounts.User

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder,
           only: [
             :user_id,
             :environment_id
           ]}
  schema "users_environments_access" do
    field(:email, :string)
    belongs_to(:user, User)
    belongs_to(:environment, Environment)
    has_many(:roles, UserEnvironmentRole, foreign_key: :access_id)

    timestamps()
  end

  def changeset(user_env_access, params \\ %{}) do
    user_env_access
    |> cast(params, [:user_id, :environment_id, :email])
    |> validate_required([:environment_id, :email])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:environment_id)
    |> unique_constraint([:user_id, :environment_id], name: :user_id_environment_id_unique_index)
    |> unique_constraint([:email, :environment_id], name: :email_environment_id_unique_index)
  end

  def new(env_id, params) do
    %__MODULE__{environment_id: env_id}
    |> __MODULE__.changeset(params)
  end
end
