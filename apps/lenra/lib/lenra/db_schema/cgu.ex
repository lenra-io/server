defmodule Lenra.Cgu do
  @moduledoc """
    The cgu schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.{Cgu, UserAcceptCguVersion}

  schema "cgu" do
    field(:link, :string)
    field(:version, :string)
    field(:hash, :string)

    many_to_many(:user_accept_cgu_version, Cgu, join_through: UserAcceptCguVersion)

    timestamps()
  end

  def changeset(cgu, params \\ %{}) do
    cgu
    |> cast(params, [:link, :version, :hash])
    |> validate_required([:link, :version, :hash])
  end

  def new(params) do
    %Cgu{}
    |> Cgu.changeset(params)
  end
end
