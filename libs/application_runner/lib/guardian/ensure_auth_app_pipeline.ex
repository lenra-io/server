defmodule ApplicationRunner.Guardian.EnsureAuthenticatedAppPipeline do
  @moduledoc """
    This pipeline ensure that the user is authenticated with an access_token and load the resource associated.
  """
  use Guardian.Plug.Pipeline,
    otp_app: :application_runner,
    error_handler: ApplicationRunner.Guardian.ErrorHandler,
    module: ApplicationRunner.Guardian.AppGuardian

  plug(Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"})
  plug(Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"})
  plug(Guardian.Plug.LoadResource)
end
