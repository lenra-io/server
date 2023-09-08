defmodule LenraCommon.Errors.DevError do
  @moduledoc """
    LenraCommon.Errors.DevError Define the DevError structure.
    This is the error to raise when we are facing an impossible case (a case that should never happen).
    This error should be caught into sentry.
  """
  @errors []

  use LenraCommon.Errors.ErrorStruct, default_status_code: 400
  use LenraCommon.Errors.ErrorGenerator, errors: @errors, module: __MODULE__

  def __errors__ do
    @errors
  end
end
