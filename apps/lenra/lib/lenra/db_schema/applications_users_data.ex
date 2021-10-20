defmodule Lenra.ApplicationsUsersData do
  @moduledoc """
    The application's users data relation shema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.{ApplicationsUsersData, ApplicationsData, User}

  schema "applications_users_data" do
    belongs_to(:user, User)
    belongs_to(:applications_data, ApplicationsData)

    timestamps()
  end

  def changeset(applications_users_data) do
    applications_users_data
    |> cast(%{}, [])
    |> validate_required([:applications_data_id, :user_id])
    |> unique_constraint(:user_app_data_unique, name: :app_users_data_user_id_app_data_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:applications_data_id)
  end

  def new(app, user) do
    %ApplicationsUsersData{applications_data_id: app.id, user_id: user.id}
    |> changeset()
  end
end
