defmodule Lenra.ApplicationMainEnv do
  @moduledoc """
    The application main env schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.{Environment, ApplicationMainEnv, LenraApplication}

  @derive {Jason.Encoder, only: [:id, :application_id, :environment_id]}
  schema "application_main_environment" do
    belongs_to(:application, LenraApplication)
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
    %ApplicationMainEnv{application_id: application_id, environment_id: environment_id}
    |> ApplicationMainEnv.changeset()
  end
end
