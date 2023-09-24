defmodule ApplicationRunner.CronHelper do
  @moduledoc """
    This is a test helper for crons.
  """

  alias ApplicationRunner.Crons
  alias ApplicationRunner.Crons.Cron

  def basic_job(env_id, function_name) do
    env_id
    |> Cron.new(function_name, %{
      "listener" => "listener",
      "schedule" => "* * * * * *"
    })
    |> Ecto.Changeset.apply_changes()
    |> Crons.to_job()
  end
end
