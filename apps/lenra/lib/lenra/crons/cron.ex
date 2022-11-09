defmodule Lenra.Crons.Cron do
  @moduledoc """
    The crons schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.Accounts.User
  alias Lenra.Apps.Environment
  alias Crontab.CronExpression.Parser

  @derive {Jason.Encoder,
           only: [
             :id,
             :listener_name,
             :schedule,
             :props,
             :should_run_missed_steps,
             :environment_id,
             :user_id,
             :overlap,
             :state,
           ]}
  schema "crons" do
    belongs_to(:environment, Environment)
    belongs_to(:user, User)

    field(:listener_name, :string)
    field(:schedule, :string)
    field(:props, :map, default: %{})

    field(:name, ApplicationRunner.Ecto.Reference)
    field(:overlap, :boolean, default: false)
    field(:state, :string, default: "active")

    field(:should_run_missed_steps, :boolean, default: false)

    timestamps()
  end

  def changeset(webhook, params \\ %{}) do
    webhook
    |> cast(params, [
      :listener_name,
      :schedule,
      :props,
      :should_run_missed_steps,
      :user_id,
      :name,
      :overlap,
      :state,
    ])
    |> validate_required([:environment_id, :listener_name, :schedule])
    |> validate_change(:schedule, fn :schedule, cron ->
      case Parser.parse(cron) do
        {:ok, _cron_expr} -> []
        _ -> [schedule: "Schedule is malformed."]
      end
    end)
    |> foreign_key_constraint(:environment_id)
    |> foreign_key_constraint(:user_id)
  end

  def update(%__MODULE__{} = cron, params) do
    changeset(cron, params)
  end

  def new(env_id, params) do
    %__MODULE__{environment_id: env_id, name: make_ref()}
    |> __MODULE__.changeset(params)
  end
end
