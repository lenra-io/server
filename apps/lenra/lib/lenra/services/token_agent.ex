defmodule Lenra.TokenAgent do
  @moduledoc """
    Lenra.SessionAgent manage token for session api request
  """
  use Agent

  alias Lenra.{EnvironmentStateServices, SessionStateServices}

  def start_link(session_state) do
    env_id = Keyword.fetch!(session_state, :env_id)

    assigns = Keyword.fetch!(session_state, :assigns)

    session_state
    |> Keyword.fetch(:session_id)
    |> case do
      {:ok, session_id} ->
        with {:ok, token} <- SessionStateServices.create_token(session_id, assigns.user.id, env_id) do
          Agent.start_link(fn -> token end, name: {:global, session_id})
        end

      :error ->
        with {:ok, token} <- EnvironmentStateServices.create_token(assigns.user.id, env_id) do
          Agent.start_link(fn -> token end, name: {:global, env_id})
        end
    end
  end
end
