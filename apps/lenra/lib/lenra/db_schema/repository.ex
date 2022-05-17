defmodule Lenra.Repository do
  @moduledoc """
    The repository schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:application_id, :url, :branch, :username, :token]}
  schema "repositories" do
    belongs_to(:application, Lenra.LenraApplication)
    field(:url, :string)
    field(:branch, :string)
    field(:username, :string)
    field(:token, :string)
    timestamps()
  end

  def changeset(application, params \\ %{}) do
    application
    |> cast(params, [:url, :branch, :username, :token])
    |> validate_required([:url])
  end

  def new(application_id, params) do
    %Lenra.Repository{application_id: application_id}
    |> changeset(params)
  end

  def update(app, params) do
    changeset(app, params)
  end
end
