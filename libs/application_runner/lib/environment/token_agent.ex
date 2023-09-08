defmodule ApplicationRunner.Environment.TokenAgent do
  @moduledoc """
    ApplicationRunner.Environment.TokenAgent manages the transaction tokens
  """
  use Agent
  use SwarmNamed

  alias ApplicationRunner.Environment

  require Logger

  def start_link(%Environment.Metadata{} = env_metadata) do
    Logger.info("Start #{__MODULE__}")
    Agent.start_link(fn -> %{} end, name: get_full_name(env_metadata.env_id))
  end

  def add_token(env_id, id, token) do
    Logger.debug("#{__MODULE__} add_token for #{env_id}")
    Agent.update(get_full_name(env_id), fn state -> Map.put(state, id, token) end)
  end

  def get_token(env_id, id) do
    Logger.debug("#{__MODULE__} get_token for #{env_id}")

    Agent.get(
      get_full_name(env_id),
      fn state ->
        Map.get(state, id)
      end
    )
  end

  def revoke_token(env_id, id) do
    Logger.debug("#{__MODULE__} revoke_token for #{env_id}")

    Agent.update(
      get_full_name(env_id),
      fn state -> Map.delete(state, id) end
    )
  end
end
