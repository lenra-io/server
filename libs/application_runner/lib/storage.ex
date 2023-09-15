defmodule ApplicationRunner.Storage do
  @moduledoc """
    ApplicationRunner.Storage implements everything needed for the crons to run properly.
  """
  alias ApplicationRunner.Crons
  alias ApplicationRunner.Crons.Cron
  alias ApplicationRunner.Repo
  alias Quantum.Storage

  @behaviour Storage

  use GenServer

  require Logger

  @doc false
  @impl GenServer
  def init(_args), do: {:ok, nil}

  @doc false
  def start_link(_opts), do: :ignore

  @impl Storage
  def add_job(_storage_pid, job) do
    with %Ecto.Changeset{valid?: true} = changeset <- Crons.to_changeset(job),
         {:ok, _res} <-
           Repo.insert(changeset,
             on_conflict:
               {:replace,
                [:schedule, :listener, :props, :should_run_missed_steps, :overlap, :state]},
             conflict_target: [:id]
           ) do
      :ok
    end
  end

  @impl Storage
  def delete_job(_storage_pid, job_name) do
    with {:ok, cron} <- Crons.get_by_name(job_name),
         {:ok, _res} <-
           Repo.delete(cron) do
      :ok
    end
  end

  @impl Storage
  def update_job(_storage_pid, job) do
    with {:ok, cron} <- Crons.get_by_name(job.name),
         {:ok, _res} <-
           Cron.update(
             cron,
             # Applying changes as a cron changeset and applying changes to properly run Cron.update
             job
             |> Crons.to_changeset()
             |> Ecto.Changeset.apply_changes()
             |> Map.from_struct()
           )
           |> Repo.update() do
      :ok
    end
  end

  @impl Storage
  def jobs(_storage_pid) do
    Crons.all() |> Enum.map(&Crons.to_job/1)
  end

  @impl Storage
  def last_execution_date(_storage_pid) do
    case Repo.get(ApplicationRunner.Quantum, 1) do
      nil -> NaiveDateTime.utc_now()
      quantum_response -> quantum_response.last_execution_date
    end
  end

  @impl Storage
  def purge(_storage_pid) do
    # We do not want to purge the crons on Lenra
    :ok
  end

  @impl Storage
  def update_job_state(_storage_pid, job_name, state) do
    with {:ok, cron} <- Crons.get_by_name(job_name),
         {:ok, _res} <-
           Cron.update(cron, %{"state" => Atom.to_string(state)})
           |> Repo.update() do
      :ok
    end
  end

  @impl Storage
  def update_last_execution_date(_storage_pid, last_execution_date) do
    with {:ok, _res} <-
           Repo.insert(ApplicationRunner.Quantum.update(last_execution_date),
             on_conflict: [set: [last_execution_date: last_execution_date]],
             conflict_target: :id
           ) do
      :ok
    end
  end
end
