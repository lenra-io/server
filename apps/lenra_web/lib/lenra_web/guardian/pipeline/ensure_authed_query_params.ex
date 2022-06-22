defmodule LenraWeb.Pipeline.EnsureAuthedQueryParams do
  @moduledoc """
    This pipeline ensure that the user is authenticated with an access_token in the query params and load the resource associated.
  """
  use Guardian.Plug.Pipeline,
    otp_app: :lenra,
    error_handler: LenraWeb.Guardian.ErrorHandler,
    module: LenraWeb.Guardian

  plug(LenraWeb.Plug.VerifyQueryParams, claims: %{"typ" => "access"})
  plug(Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"})
  plug(Guardian.Plug.LoadResource)
end
