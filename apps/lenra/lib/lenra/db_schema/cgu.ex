defmodule Lenra.Cgu do
  @moduledoc """
    The cgu schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.{Cgu, User, UserAcceptCguVersion}

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

    many_to_many(:users, User, join_through: UserAcceptCguVersion)

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
    %Cgu{}
    |> Cgu.changeset(params)
  end
end
