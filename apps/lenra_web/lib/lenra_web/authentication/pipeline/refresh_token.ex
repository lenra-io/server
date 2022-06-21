defmodule LenraWeb.Pipeline.RefreshToken do
  @moduledoc """
   Lenra.Pipeline.RefreshToken is the pipeline that allow to check if the refresh token is available and load the associated user.
  """

  use Guardian.Plug.Pipeline,
    otp_app: :lenra,
    error_handler: LenraWeb.Guardian.ErrorHandler,
    module: LenraWeb.Guardian

  plug(LenraWeb.Plug.VerifyCookieSimple,
    claims: %{"typ" => "refresh"}
  )

  plug(Guardian.Plug.EnsureAuthenticated,
    claims: %{"typ" => "refresh"}
  )

  plug(Guardian.Plug.LoadResource)
end
