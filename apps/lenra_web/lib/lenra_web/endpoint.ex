defmodule LenraWeb.Endpoint do
  use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :lenra_web

  # Sentry stuff to capture errors

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_lenra_key",
    signing_salt: "MFyEizGS"
  ]

  socket("/socket", LenraWeb.AppSocket,
    websocket: true,
    longpoll: false
  )

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  plug(Stripe.WebhookPlug,
    at: "/webhook/stripe",
    handler: Lenra.StripeHandler,
    secret: {Application, :get_env, [:lenra, :webhook_secret]}
  )

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  if Mix.env() == :dev do
    plug(Plug.Static,
      at: "/web",
      from: :lenra_web,
      gzip: false,
      only: ~w(html css fonts images js favicon.ico robots.txt cgs),
      headers: %{
        "Access-Control-Allow-Origin" => "http://localhost:10000",
        "Access-Control-Allow-Methods" => "GET, OPTIONS",
        "Access-Control-Allow-Headers" => "Accept, Content-Type, X-Requested-With, X-CSRF-Token, Authorization",
        "Access-Control-Allow-Credentials" => "true",
        "Access-Control-Max-Age" => "240"
      }
    )
  else
    plug(Plug.Static,
      at: "/web",
      from: :lenra_web,
      gzip: false,
      only: ~w(html css fonts images js favicon.ico robots.txt cgs)
    )
  end

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  plug(Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"
  )

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  # Gather information about the context for sentry
  plug(Sentry.PlugContext)

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)

  if Mix.env() == :dev do
    plug(CORSPlug)
  end

  plug(LenraWeb.Router)
end
