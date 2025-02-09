defmodule ApplicationRunner.Environment do
  @moduledoc """
    ApplicationRunner.Environment manage Environments.
  """

  alias ApplicationRunner.Environment

  defdelegate get_manifest(env_id), to: Environment.ManifestHandler

  defdelegate ensure_env_started(env_metadata), to: Environment.DynamicSupervisor

  defdelegate update_env_scale_options(env_id, scale_opts), to: Environment.DynamicSupervisor
end
