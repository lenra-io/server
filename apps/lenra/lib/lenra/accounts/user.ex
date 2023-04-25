defmodule Lenra.Accounts.User do
  @moduledoc """
    The user shema.
  """
  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Apps.UserEnvironmentAccess

  alias Lenra.Accounts.{
    LostPasswordCode,
    Password,
    RegistrationCode,
    User
  }

  alias Lenra.Apps.{
    App,
    Build,
    Deployment,
    Environment
  }

  alias Lenra.Legal.{CGU, UserAcceptCGUVersion}

  @type t :: %__MODULE__{}

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
    has_many(:applications, App, foreign_key: :creator_id)
    has_one(:password_code, LostPasswordCode)
    has_many(:builds, Build, foreign_key: :creator_id)
    has_many(:environments, Environment, foreign_key: :creator_id)
    has_many(:deployments, Deployment, foreign_key: :publisher_id)
    many_to_many(:environments_accesses, Environment, join_through: UserEnvironmentAccess)
    many_to_many(:cgus, CGU, join_through: UserAcceptCGUVersion)
    timestamps()
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:first_name, :last_name, :email])
    |> cast_assoc(:password, with: &Password.changeset/2)
    |> validate_email()
    |> validate_required([:role])
    |> validate_length(:first_name, min: 2, max: 256)
    |> validate_length(:last_name, min: 2, max: 256)
    |> validate_inclusion(:role, @all_roles)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, @email_regex)
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Lenra.Repo)
    |> unique_constraint(:email)
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

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> cast_assoc(:password, required: true)
    |> validate_email()
  end
end
