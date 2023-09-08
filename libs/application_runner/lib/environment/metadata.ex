defmodule ApplicationRunner.Environment.Metadata do
  @moduledoc """
    The Environment metadata.
  """
  @enforce_keys [:env_id, :function_name]
  defstruct [
    :env_id,
    :function_name
  ]

  @type t :: %__MODULE__{
          env_id: term(),
          function_name: term()
        }
end
