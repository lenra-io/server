defmodule LenraWeb.Errors.BusinessError do
  @moduledoc """
    LenraWeb.Errors.BusinessError handles business errors for the LenraWeb app.
    This module uses LenraCommon.Errors.BusinessError
  """

  use LenraCommon.Errors.ErrorGenerator,
    module: LenraCommon.Errors.BusinessError,
    inherit: true,
    errors: [
      {:invalid_token, "The token is invalid."},
      {:token_not_found, "No Bearer token found in Authorization header"}
    ]
end
