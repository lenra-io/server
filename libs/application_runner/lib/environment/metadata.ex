defmodule ApplicationRunner.Environment.Metadata do
  @moduledoc """
    The Environment metadata.
  """
  @enforce_keys [:env_id, :function_name]
  defstruct [
    :env_id,
    :function_name,
    :scale_min,
    :scale_max
  ]

  @type t :: %__MODULE__{
          env_id: term(),
          function_name: term(),
          scale_min: non_neg_integer(),
          scale_max: non_neg_integer()
        }
end
