defmodule Lenra.Guardian.EnsureAuthenticatedQueryParamsPipeline do
  @moduledoc """
    This pipeline ensure that the user is authenticated with an access_token and load the resource associated.
  """
  use Guardian.Plug.Pipeline,
    otp_app: :lenra,
    error_handler: Lenra.Guardian.ErrorHandler,
    module: Lenra.Guardian

  plug(Lenra.Guardian.Plug.VerifyQueryParams, claims: %{"typ" => "access"})
  plug(Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"})
  plug(Guardian.Plug.LoadResource)
end
