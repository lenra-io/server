defmodule Lenra.Cgu do
  @moduledoc """
    The cgu schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.{Cgu}

  schema "cgu" do
    field(:link, :string)
    field(:version, :string)
    field(:hash, :string)
    timestamps()
  end

  def changeset(cgu, params \\ %{}) do
    cgu
    |> cast(params, [:link, :version, :hash])
    |> validate_required([:link, :version, :hash])
  end

  def new(link, version, hash) do
    %Cgu{}
    |> Cgu.changeset(%{link: link, version: version, hash: hash})
  end
end
