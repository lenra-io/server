defmodule Lenra.Guardian.RefreshPipeline do
  @moduledoc """
   Lenra.Guardian.RefreshPipeline is the pipeline that allow to check if the refresh token is available and load the associated user.
  """

  use Guardian.Plug.Pipeline,
    otp_app: :lenra,
    error_handler: Lenra.Guardian.ErrorHandler,
    module: Lenra.Guardian

  plug(Lenra.Plug.SimpleVerifyCookie,
    claims: %{"typ" => "refresh"}
  )

  plug(Guardian.Plug.EnsureAuthenticated,
    claims: %{"typ" => "refresh"}
  )

  plug(Guardian.Plug.LoadResource)
end
