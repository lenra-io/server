defmodule Lenra.Errors.BusinessError do
  @type t() :: %__MODULE__{
          message: String.t(),
          reason: atom(),
          data: any()
        }

  @enforce_keys [:message, :reason]
  defexception [:message, :reason, :data]
end

defmodule Lenra.Errors.TechnicalError do
  @type t() :: %__MODULE__{
          message: String.t(),
          reason: atom(),
          data: any()
        }

  @enforce_keys [:message, :reason]
  defexception [:message, :reason, :data]
end

defmodule Lenra.Errors.DevError do
  @type t() :: %__MODULE__{
          message: String.t(),
          reason: atom(),
          data: any()
        }

  @enforce_keys [:message, :reason]
  defexception [:message, :reason, :data]

  def message(%{message: message}) when is_bitstring(message) do
    message
  end

  def message(_e) do
    "An unknown error occured."
  end
end

# defmodule Test do
#   def business_error do
#     {:error, Lenra.Errors.BusinessError.exception(message: "This account does not exists.", reason: :invalid_account)}
#   end

#   def tech_error do
#     {:error,
#      Lenra.Errors.TechnicalError.exception(
#        message: "Openfaas not reachable. Please retry later !",
#        reason: :openfaas_not_reachable
#      )}
#   end

#   def exception do
#     raise Lenra.Errors.DevError, "Snap, we should not go into this !"
#   end
# end
