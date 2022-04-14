defmodule Lenra.SessionAgent do
  @moduledoc """
    Lenra.SessionAgent manage token for session api request
  """
  use Agent

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: {:global, __MODULE__})
  end

  def add_token(session_id, token) do
    Agent.update({:global, __MODULE__}, &Map.merge(&1, %{session_id => token}))
  end

  def revoke_token(session_id) do
    Agent.update({:global, __MODULE__}, &Map.delete(&1, session_id))
  end

  def fetch_token(session_id) do
    Agent.get({:global, __MODULE__}, &Map.get(&1, session_id))
  end
end
