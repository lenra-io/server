defmodule ApplicationRunner.Environment.MetadataAgent do
  @moduledoc """
    ApplicationRunner.Environment.MetadataAgent manages environment state
  """
  use Agent
  use SwarmNamed

  alias ApplicationRunner.Environment

  require Logger

  def start_link(%Environment.Metadata{} = env_metadata) do
    Logger.info("Start #{__MODULE__}")
    Agent.start_link(fn -> env_metadata end, name: get_full_name(env_metadata.env_id))
  end

  @spec get_metadata(any()) :: Environment.Metadata.t()
  def get_metadata(env_id) do
    Logger.debug("#{__MODULE__} get_metadata for #{env_id}")

    Agent.get(
      get_full_name(env_id),
      fn %Environment.Metadata{} = env_metadata ->
        env_metadata
      end
    )
  end
end
