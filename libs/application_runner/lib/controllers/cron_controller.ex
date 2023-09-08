defmodule ApplicationRunner.CronController do
  use ApplicationRunner, :controller

  alias ApplicationRunner.Crons
  alias ApplicationRunner.Ecto.Reference
  alias ApplicationRunner.Environment
  alias ApplicationRunner.Environment.MetadataAgent
  alias ApplicationRunner.Errors.{BusinessError, TechnicalError}
  alias ApplicationRunner.Guardian.AppGuardian

  def create(conn, params) do
    with %{environment: env} <- AppGuardian.Plug.current_resource(conn),
         %Environment.Metadata{} = metadata <- MetadataAgent.get_metadata(env.id),
         {:ok, name} <-
           Crons.create(env.id, metadata.function_name, params) do
      reply(conn, name)
    else
      nil -> BusinessError.invalid_token_tuple()
      err -> err
    end
  end

  # TODO: This method will be used when we implement the cron UI on the backoffice
  # def get(conn, %{"name" => cron_name} = _params) do
  #   with {:ok, cron} <-
  #          Crons.get_by_name(cron_name) do
  #     reply(conn, cron)
  #   end
  # end

  def index(conn, _params) do
    case AppGuardian.Plug.current_resource(conn) do
      nil ->
        raise BusinessError.invalid_token()

      %{environment: env} ->
        reply(conn, Crons.all(env.id))
    end
  end

  def update(conn, %{"name" => name} = params) do
    {:ok, loaded_name} = Reference.load(name)

    with %{environment: env} <- AppGuardian.Plug.current_resource(conn),
         {:ok, cron} <- Crons.get_by_name(loaded_name),
         true <- env.id == cron.environment_id,
         :ok <- Crons.update(cron, params) do
      reply(conn, :ok)
    else
      false -> TechnicalError.unauthorized_tuple()
      err -> err
    end
  end

  def delete(conn, %{"name" => name} = _params) do
    {:ok, loaded_name} = Reference.load(name)

    with %{environment: env} <- AppGuardian.Plug.current_resource(conn),
         {:ok, cron} <- Crons.get_by_name(loaded_name),
         true <- env.id == cron.environment_id,
         :ok <- Crons.delete(loaded_name) do
      reply(conn, :ok)
    else
      false -> TechnicalError.unauthorized_tuple()
      err -> err
    end
  end
end
