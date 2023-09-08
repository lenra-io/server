defmodule ApplicationRunner.Crons.Cron do
  @moduledoc """
    The crons schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias ApplicationRunner.Contract.{Environment, User}
  alias Crontab.CronExpression.Parser

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :listener_name,
             :schedule,
             :props,
             :should_run_missed_steps,
             :environment_id,
             :user_id,
             :overlap,
             :state,
             :function_name
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
    field(:function_name, :string)

    timestamps()
  end

  def changeset(cron, params \\ %{}) do
    cron
    |> cast(params, [
      :listener_name,
      :schedule,
      :props,
      :should_run_missed_steps,
      :user_id,
      :name,
      :overlap,
      :state
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

  def new(env_id, function_name, params) do
    %__MODULE__{environment_id: env_id, function_name: function_name, name: make_ref()}
    |> __MODULE__.changeset(params)
  end
end
