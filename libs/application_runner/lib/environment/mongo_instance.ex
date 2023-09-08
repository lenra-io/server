defmodule ApplicationRunner.Environment.MongoInstance do
  @moduledoc """
    This module provides some tools to manage `Mongo` genserver.
  """
  require Logger

  use SwarmNamed

  @doc """
    Returns the config options to start the `Mongo` genserver in the environment supervisor, for the given env_id.
  """
  def config(env_id) do
    env = Application.fetch_env!(:application_runner, :env)

    database_name = env <> "_#{env_id}"

    Logger.debug("#{__MODULE__} config for #{env_id} with db_name #{database_name}")

    mongo_config = Application.fetch_env!(:application_runner, :mongo)

    case Integer.parse(mongo_config[:port]) do
      {port, _} ->
        [
          hostname: mongo_config[:hostname],
          port: port,
          database: database_name,
          username: mongo_config[:username],
          password: mongo_config[:password],
          ssl: mongo_config[:ssl],
          name: get_full_name(env_id),
          auth_source: mongo_config[:auth_source],
          pool_size: 10
        ]

      :error ->
        error = "Failed to parse Mongo port: " <> mongo_config[:port]

        raise error
    end
  end

  def run_mongo_task(env_id, mod, fun, opts) do
    Logger.debug(
      "#{__MODULE__} run_mongo_task for #{env_id} with task #{inspect([mod, fun, opts])}"
    )

    res =
      Task.Supervisor.async(
        {:via, :swarm,
         {ApplicationRunner.Environment.MongoInstance.TaskSupervisor, get_name(env_id)}},
        fn -> Kernel.apply(mod, fun, opts) end
      )
      |> Task.await()

    Logger.debug(
      "#{__MODULE__} run_mongo_task for #{env_id} with task #{inspect([mod, fun, opts])} result with #{inspect(res)}"
    )

    res
  end
end

defimpl Jason.Encoder, for: Mongo.Error do
  def encode(struct, _opts \\ []) do
    Jason.encode!(%{
      code: struct.code,
      message: struct.message
    })
  end
end

defimpl Jason.Encoder, for: BSON.ObjectId do
  def encode(val, _opts \\ []) do
    val
    |> BSON.ObjectId.encode!()
    |> to_object_id_str()
    |> Jason.encode!()
  end

  defp to_object_id_str(str) do
    "ObjectId(#{str})"
  end
end
