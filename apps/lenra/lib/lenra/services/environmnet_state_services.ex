defmodule Lenra.EnvironmentStateServices do
  @moduledoc """
    Lenra.Sessionstate handle all operation for session state.
  """

  alias ApplicationRunner.EnvSupervisor
  alias LenraWeb.AppGuardian

  def create_token(user_id, env_id) do
    with {:ok, token, _claims} <-
           AppGuardian.encode_and_sign(env_id, %{type: "env", user_id: user_id, env_id: env_id}) do
      {:ok, token}
    end
  end

  def fetch_token(env_id) do
    with agent <- EnvSupervisor.fetch_module_pid!(env_id, Lenra.TokenAgent) do
      Agent.get(agent, fn state -> state end)
    end
  end
end
