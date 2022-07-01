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
             :link,
             :version,
             :hash
           ]}

  schema "cgu" do
    field(:link, :string)
    field(:version, :string)
    field(:hash, :string)

    many_to_many(:users, User, join_through: UserAcceptCGUVersion)

    timestamps()
  end

  def changeset(cgu, params \\ %{}) do
    cgu
    |> cast(params, [:link, :version, :hash])
    |> validate_required([:link, :version, :hash])
    |> unique_constraint([:link])
    |> unique_constraint([:version])
    |> unique_constraint([:hash])
  end

  def new(params) do
    %__MODULE__{}
    |> __MODULE__.changeset(params)
  end
end
