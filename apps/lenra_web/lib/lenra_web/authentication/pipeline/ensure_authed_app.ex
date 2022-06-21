defmodule LenraWeb.Pipeline.EnsureAuthedApp do
  @moduledoc """
    This pipeline ensure that the user is authenticated with an access_token and load the resource associated.
  """
  use Guardian.Plug.Pipeline,
    otp_app: :lenra,
    error_handler: LenraWeb.Guardian.ErrorHandler,
    module: LenraWeb.AppGuardian

  plug(Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"})
  plug(Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"})
  plug(Guardian.Plug.LoadResource)
end
