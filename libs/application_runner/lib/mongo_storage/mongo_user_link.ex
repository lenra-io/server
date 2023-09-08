defmodule ApplicationRunner.MongoStorage.MongoUserLink do
  @moduledoc """
    The MongoUser schema.
    This schema create the link between the User in Postgres and the user in the mongo app system.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias ApplicationRunner.Contract.{Environment, User}

  @primary_key {:mongo_user_id, Ecto.UUID, autogenerate: true}
  schema "mongo_user_link" do
    belongs_to(:user, User)
    belongs_to(:environment, Environment)
    timestamps()
  end

  def changeset(mongo_user_link, params \\ %{}) do
    mongo_user_link
    |> cast(params, [:environment_id, :user_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:environment_id)
    |> validate_required([])
  end

  def new(params) do
    %__MODULE__{}
    |> __MODULE__.changeset(params)
  end
end
