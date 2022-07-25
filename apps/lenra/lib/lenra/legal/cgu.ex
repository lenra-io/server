defmodule Lenra.Legal.CGU do
  @moduledoc """
    The cgu schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Accounts.User
  alias Lenra.Legal.UserAcceptCGUVersion

  @derive {Jason.Encoder,
           only: [
             :id,
             :path,
             :version,
             :hash
           ]}

  schema "cgu" do
    field(:path, :string)
    field(:version, :integer)
    field(:hash, :string)

    many_to_many(:users, User, join_through: UserAcceptCGUVersion)

    timestamps()
  end

  def changeset(cgu, params \\ %{}) do
    cgu
    |> cast(params, [:path, :version, :hash])
    |> validate_required([:path, :version, :hash])
    |> unique_constraint([:path])
    |> unique_constraint([:version])
    |> unique_constraint([:hash])
  end

  def new(params) do
    %__MODULE__{}
    |> __MODULE__.changeset(params)
  end
end
