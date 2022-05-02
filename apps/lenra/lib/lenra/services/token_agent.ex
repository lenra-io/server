defmodule Lenra.TokenAgent do
  @moduledoc """
    Lenra.SessionAgent manage token for session api request
  """
  use Agent

  alias Lenra.{EnvironmentStateServices, SessionStateServices}

  def start_link(env_id: env_id, session_id: session_id, assigns: %{user: user}) do
    with {:ok, token} <- SessionStateServices.create_token(session_id, user.id, env_id) do
      Agent.start_link(fn -> token end, name: {:global, session_id})
    end
  end

  def start_link(env_id: env_id, assigns: %{user: user}) do
    with {:ok, token} <- EnvironmentStateServices.create_token(user.id, env_id) do
      Agent.start_link(fn -> token end, name: {:global, env_id})
    end
  end
end
