defmodule Lenra.Guardian.EnsureAuthenticatedPreCgu do
  @moduledoc """
    This pipeline ensure that the user is authenticated with an access_token and load the resource associated.
  """
  use Guardian.Plug.Pipeline,
    otp_app: :lenra,
    error_handler: Lenra.Guardian.ErrorHandler,
    module: Lenra.Guardian

  plug(Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}, check_cgu: false)
  plug(Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"})
  plug(Guardian.Plug.LoadResource)
  # TODO: Change plugs to ensure that the user is authenticated but not fully because he did not accept the cgus
end
