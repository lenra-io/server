defmodule ApplicationRunner.Session.State do
  @moduledoc """
    The State struct.
  """
  @enforce_keys [:session_id, :env_id, :user_id, :function_name]
  defstruct [
    :session_id,
    :env_id,
    :user_id,
    :function_name,
    :session_supervisor_pid,
    :inactivity_timeout,
    :assigns,
    :context,
    :token
  ]

  @type t :: %__MODULE__{
          session_id: integer(),
          env_id: term(),
          user_id: term(),
          function_name: String.t(),
          session_supervisor_pid: pid(),
          inactivity_timeout: number(),
          assigns: term(),
          context: map(),
          token: String.t()
        }
end
