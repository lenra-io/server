defmodule Lenra.Apps.MainEnv do
  @moduledoc """
    The application main env schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Apps.{
    App,
    Environment
  }

  @derive {Jason.Encoder, only: [:id, :application_id, :environment_id]}
  schema "application_main_environment" do
    belongs_to(:application, App)
    belongs_to(:environment, Environment)

    timestamps()
  end

  def changeset(app_main_env, params \\ %{}) do
    app_main_env
    |> cast(params, [])
    |> validate_required([:application_id, :environment_id])
    |> foreign_key_constraint(:application_id)
    |> foreign_key_constraint(:environment_id)
  end

  def new(application_id, environment_id) do
    %__MODULE__{application_id: application_id, environment_id: environment_id}
    |> __MODULE__.changeset()
  end
end
