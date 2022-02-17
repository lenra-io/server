defmodule Lenra.UserEnvironmentAccess do
  @moduledoc """
    The user environment access schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.{User, Environment}

  @derive {Jason.Encoder,
           only: [
             :user_id,
             :environment_id
           ]}
  @primary_key false
  schema "users_environments_access" do
    belongs_to(:user, User)
    belongs_to(:environment, Environment)

    timestamps()
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:user_id, :environment_id])
    |> validate_required([:user_id, :environment_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:environment_id)
    |> unique_constraint([:user_id, :environment_id], name: :users_environments_access_pkey)
  end
end
