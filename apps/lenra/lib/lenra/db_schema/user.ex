defmodule Lenra.User do
  @moduledoc """
    The user shema.
  """
  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.{
    Build,
    Datastore,
    Deployment,
    DevCode,
    Environment,
    LenraApplication,
    Password,
    PasswordCode,
    RegistrationCode,
    User,
    UserAcceptCguVersion,
    UserEnvironmentAccess
  }

  @email_regex ~r/[^@]+@[^\.]+\..+/

  @unverified_user_role :unverified_user
  @user_role :user
  @dev_role :dev
  @admin_role :admin
  @all_roles [@unverified_user_role, @user_role, @admin_role, @dev_role]

  @derive {Jason.Encoder, only: [:id, :role, :first_name, :last_name, :email]}
  schema "users" do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:email, :string)
    has_many(:password, Password)
    field(:role, Ecto.Enum, values: [:admin, :dev, :user, :unverified_user])
    has_one(:registration_code, RegistrationCode)
    has_many(:applications, LenraApplication, foreign_key: :creator_id)
    has_many(:datastores, Datastore)
    has_one(:password_code, PasswordCode)
    has_many(:builds, Build, foreign_key: :creator_id)
    has_many(:environments, Environment, foreign_key: :creator_id)
    has_many(:deployments, Deployment, foreign_key: :publisher_id)
    has_one(:dev_code, DevCode)
    many_to_many(:environments_accesses, Environment, join_through: UserEnvironmentAccess)

    many_to_many(:cgus, Lenra.Cgu, join_through: UserAcceptCguVersion)

    timestamps()
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:first_name, :last_name, :email])
    |> validate_required([:email, :role])
    |> validate_length(:first_name, min: 2, max: 256)
    |> validate_length(:last_name, min: 2, max: 256)
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, @email_regex)
    |> unique_constraint(:email)
    |> validate_inclusion(:role, @all_roles)
  end

  def change_role(user, role) do
    user
    |> cast(%{role: role}, [:role])
    |> changeset()
  end

  @spec new(:invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}, any) ::
          Ecto.Changeset.t()
  def new(params, role) do
    %User{role: role || @unverified_user_role}
    |> changeset(params)
  end

  def update(%User{} = user, params) do
    changeset(user, params)
  end
end
