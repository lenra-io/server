defmodule ApplicationRunner.Session.Metadata do
  @moduledoc """
    The Metadata struct.
  """
  @enforce_keys [:session_id, :env_id, :user_id, :roles, :function_name, :context]
  defstruct [
    :env_id,
    :session_id,
    :user_id,
    :roles,
    :function_name,
    :context
  ]

  @type t :: %__MODULE__{
          env_id: term(),
          session_id: integer(),
          user_id: term(),
          roles: list(binary()),
          function_name: String.t(),
          context: map()
        }
end
