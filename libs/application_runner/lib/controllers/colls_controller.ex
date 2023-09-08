defmodule ApplicationRunner.CollsController do
  use ApplicationRunner, :controller

  alias ApplicationRunner.Environment.MongoInstance
  alias ApplicationRunner.MongoStorage

  require Logger

  def delete(conn, %{"coll" => coll}) do
    Logger.debug("#{__MODULE__} handle DELETE on collection #{coll}")

    with %{environment: env} <- Guardian.Plug.current_resource(conn),
         :ok <- Logger.debug("#{__MODULE__} load #{inspect(env)} from token"),
         :ok <- MongoInstance.run_mongo_task(env.id, MongoStorage, :delete_coll, [env.id, coll]) do
      reply(conn)
    end
  end
end
