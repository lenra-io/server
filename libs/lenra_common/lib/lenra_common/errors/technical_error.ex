defmodule LenraCommon.Errors.TechnicalError do
  @moduledoc """
    LenraCommon.Errors.TechnicalError creates all error functions based on the `@errors` list.
    For each error in the list, this module creates two function,
    one that creates and returns a TechnicalError struct,
    the second that creates a TechnicalError struct and returns it into an tuple.
  """

  @errors [
    {:unknown_error, "Unknown error"},
    {:bad_request, "Server cannot understand or process the request due to a client-side error.",
     400},
    {:error_404, "Not Found.", 404},
    {:error_500, "Internal server error.", 500}
  ]
  use LenraCommon.Errors.ErrorStruct, default_status_code: 500
  use LenraCommon.Errors.ErrorGenerator, errors: @errors, module: __MODULE__

  def __errors__ do
    @errors
  end
end
