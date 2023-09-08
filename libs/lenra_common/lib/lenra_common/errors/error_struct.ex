defmodule LenraCommon.Errors.ErrorStruct do
  @moduledoc """
    LenraCommon.Errors.ErrorStruct defines a basic error struct for Lenra server.
  """
  defmacro __using__(opts) do
    default_status_code = Keyword.fetch!(opts, :default_status_code)

    quote do
      @derive {Jason.Encoder, only: [:message, :reason, :metadata, :status_code]}
      @type t() :: %__MODULE__{
              message: String.t(),
              reason: atom(),
              metadata: any(),
              status_code: integer()
            }

      @enforce_keys [:message, :reason]
      defexception [:message, :reason, :metadata, status_code: unquote(default_status_code)]
    end
  end
end
