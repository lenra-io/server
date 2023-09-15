defmodule ApplicationRunner.Session.ListenersCache do
  @moduledoc """
    This module creates a Cache for all the listeners.
    It save the listener props/name using a hash the value (sha256) as key.
    Then we can retrieve the listener (name/props) by giving the key.
  """
  use Agent
  use SwarmNamed

  alias ApplicationRunner.Errors.BusinessError

  def start_link(opts) do
    session_id = Keyword.fetch!(opts, :session_id)
    Agent.start_link(fn -> %{} end, name: get_full_name(session_id))
  end

  @spec create_code(String.t(), map()) :: String.t()
  def create_code(name, props) do
    Crypto.hash({name, props})
  end

  @spec save_listener(any(), String.t(), map()) :: :ok
  def save_listener(session_id, code, listener) do
    Agent.update(get_full_name(session_id), fn cache ->
      Map.put(cache, code, listener)
    end)
  end

  @spec fetch_listener(any(), String.t()) :: {:ok, map()} | {:error, atom()}
  def fetch_listener(session_id, code) do
    Agent.get(get_full_name(session_id), fn cache ->
      case Map.fetch(cache, code) do
        :error -> BusinessError.unknow_listener_code_tuple(code)
        res -> res
      end
    end)
  end
end
