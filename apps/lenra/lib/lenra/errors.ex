defmodule Lenra.Errors do
  defmodule BusinessError do
    @type t() :: %__MODULE__{
            message: String.t(),
            reason: atom(),
            data: any()
          }

    @enforce_keys [:message, :reason]
    defexception [:message, :reason, :data]
  end

  defmodule TechnicalError do
    @type t() :: %__MODULE__{
            message: String.t(),
            reason: atom(),
            data: any()
          }

    @enforce_keys [:message, :reason]
    defexception [:message, :reason, :data]
  end

  defmodule DevError do
    defexception [:message, :data]

    def message(%{message: message}) when is_bitstring(message) do
      message
    end

    def message(_e) do
      "An unknown error occured."
    end
  end
end

defmodule Test do
  def business_error do
    {:error, Lenra.Errors.BusinessError.exception(message: "This account does not exists.", reason: :invalid_account)}
  end

  def tech_error do
    {:error,
     Lenra.Errors.TechnicalError.exception(
       message: "Openfaas not reachable. Please retry later !",
       reason: :openfaas_not_reachable
     )}
  end

  def exception do
    raise Lenra.Errors.DevError, "Snap, we should not go into this !"
  end
end
