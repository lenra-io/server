defmodule ApplicationRunner.Crons do
  @moduledoc """
    ApplicationRunner.Crons delegates methods to the corresponding service.
  """

  import Ecto.Query, only: [from: 2, from: 1]

  alias ApplicationRunner.Crons.Cron
  alias ApplicationRunner.Errors.{BusinessError, TechnicalError}
  alias ApplicationRunner.{AppSocket, Environment, EventHandler, Repo}
  alias Crontab.CronExpression.{Composer, Parser}

  def run_env_cron(
        listener,
        props,
        event,
        env_id,
        function_name
      ) do
    with {:ok, _pid} <-
           Environment.ensure_env_started(%Environment.Metadata{
             env_id: env_id,
             function_name: function_name
           }) do
      EventHandler.send_env_event(env_id, listener, props, event)
    end
  end

  def create(env_id, function_name, %{"listener" => _listener} = params) do
    with {:ok, cron} <-
           env_id
           |> Cron.new(function_name, params)
           |> Ecto.Changeset.apply_action(:new) do
      cron
      |> to_job()
      |> ApplicationRunner.Scheduler.add_job()

      # Only the name is returned here because the cron is not inserted yet.
      {:ok, cron.name}
    end
  end

  def create(_env_id, params) do
    BusinessError.invalid_params_tuple(params)
  end

  def get(id) do
    case Repo.get(Cron, id) do
      nil -> TechnicalError.cron_not_found_tuple(id)
      cron -> {:ok, cron}
    end
  end

  def get_by_name(name) do
    case Repo.get_by(Cron, name: name) do
      nil -> TechnicalError.error_404_tuple(name)
      cron -> {:ok, cron}
    end
  end

  def all do
    Repo.all(from(c in Cron))
  end

  def all(env_id) do
    Repo.all(from(c in Cron, where: c.environment_id == ^env_id))
  end

  def all(env_id, user_id) do
    Repo.all(from(c in Cron, where: c.environment_id == ^env_id and c.user_id == ^user_id))
  end

  def update(cron, params) do
    # Quantum's default behavior will update the job when using the add_job.
    # There is no Scheduler.update_job method.
    with %Ecto.Changeset{valid?: true} = changeset <-
           cron
           |> Cron.update(params) do
      changeset
      |> Ecto.Changeset.apply_changes()
      |> to_job()
      |> ApplicationRunner.Scheduler.add_job()
    end
  end

  def delete(cron_name) do
    cron_name
    |> ApplicationRunner.Scheduler.delete_job()
  end

  def to_job(cron) do
    with {:ok, schedule} <- Parser.parse(cron.schedule) do
      ApplicationRunner.Scheduler.new_job(
        name: cron.name,
        overlap: cron.overlap,
        state: String.to_existing_atom(cron.state),
        schedule: schedule,
        task:
          {ApplicationRunner.Crons, :run_env_cron,
           [
             cron.listener,
             cron.props,
             %{},
             cron.environment_id,
             cron.function_name
           ]}
      )
    end
  end

  def to_changeset(%Quantum.Job{
        name: name,
        overlap: overlap,
        schedule: schedule,
        state: state,
        task: {_, _, [listener, props, _, env_id, function_name]}
      }) do
    Cron.new(env_id, function_name, %{
      "listener" => listener,
      "schedule" => Composer.compose(schedule),
      "props" => props,
      "name" => name,
      "overlap" => overlap,
      "state" => Atom.to_string(state)
    })
  end

  def to_changeset(invalid_job) do
    BusinessError.invalid_params_tuple(invalid_job)
  end

  defdelegate new(env_id, function_name, params), to: Cron
end
