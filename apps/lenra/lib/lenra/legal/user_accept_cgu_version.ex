defmodule Lenra.Legal.UserAcceptCGSVersion do
  @moduledoc """
    The user acceptation of the cgs version.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Accounts.User
  alias Lenra.Legal.CGS

  @derive {Jason.Encoder,
           only: [
             :user_id,
             :cgs_id
           ]}
  @primary_key false
  schema "user_accept_cgs_versions" do
    belongs_to(:user, User, primary_key: true)
    belongs_to(:cgs, CGS, primary_key: true)

    timestamps()
  end

  def changeset(user_accept_cgs_versions, params \\ %{}) do
    user_accept_cgs_versions
    |> cast(params, [:user_id, :cgs_id])
    |> validate_required([:user_id, :cgs_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:cgs_id)
    |> unique_constraint([:user_id, :cgs_id], name: :user_accept_cgs_versions_pkey)
  end

  def new(params) do
    %__MODULE__{}
    |> __MODULE__.changeset(params)
  end
end
