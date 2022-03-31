defmodule Lenra.UserAcceptCguVersion do
  @moduledoc """
    The user acceptation of the cgu version.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.{Cgu, User, UserAcceptCguVersion}

  @derive {Jason.Encoder,
           only: [
             :user_id,
             :cgu_id
           ]}
  @primary_key false
  schema "user_accept_cgu_versions" do
    belongs_to(:user, User, primary_key: true)
    belongs_to(:cgu, Cgu, primary_key: true)

    timestamps()
  end

  def changeset(user_accept_cgu_versions, params \\ %{}) do
    user_accept_cgu_versions
    |> cast(params, [:user_id, :cgu_id])
    |> validate_required([:user_id, :cgu_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:cgu_id)
    |> unique_constraint([:user_id, :cgu_id], name: :user_accept_cgu_versions_pkey)
  end

  def new(params) do
    %UserAcceptCguVersion{}
    |> UserAcceptCguVersion.changeset(params)
  end
end