defmodule LenraWeb.Router do
  use LenraWeb, :router

  alias LenraWeb.Plug

  require ApplicationRunner.Router

  ApplicationRunner.Router.app_routes()

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_session)
  end

  pipeline :runner do
    plug(Plug.VerifyRunnerSecret)
  end

  pipeline :ensure_cgs_accepted do
    plug(Plug.VerifyCgs)
  end

  pipeline :scope_profile do
    plug(Plug.ExtractBearer)
    plug(Plug.VerifyScope, "profile")
  end

  pipeline :scope_manage_account do
    plug(Plug.ExtractBearer)
    plug(Plug.VerifyScope, "manage:account")
  end

  pipeline :scope_manage_apps do
    plug(Plug.ExtractBearer)
    plug(Plug.VerifyScope, "manage:apps")
  end

  pipeline :scope_payments do
    plug(Plug.ExtractBearer)
    plug(Plug.VerifyScope, "manage:payments")
  end

  pipeline :scope_store do
    plug(Plug.ExtractBearer)
    plug(Plug.VerifyScope, "store")
  end

  pipeline :scope_resources do
    plug(Plug.ExtractQueryParams)
    plug(Plug.VerifyScope, "resources")
  end

  # Runner callback, secured via runner-specific token
  scope "/runner", LenraWeb do
    pipe_through([:api, :runner])
    put("/builds/:id", RunnerController, :update_build)
  end

  # /api, No scope needed
  scope "/api", LenraWeb do
    pipe_through([:api])
    get("/cgs/latest", CgsController, :get_latest_cgs)
    get("/apps/:app_service_name", AppsController, :get_app_by_service_name)
  end

  # /api, scope "profile"
  scope "/api", LenraWeb do
    pipe_through([:scope_profile])
    get("/me", UserController, :current_user)
  end

  # /api, scope "manage_account" without CGS needed
  scope "/api", LenraWeb do
    pipe_through([:api, :scope_manage_account])
    post("/cgs/:cgs_id/accept", CgsController, :accept)
    get("/cgs/me/accepted_latest", CgsController, :user_accepted_latest_cgs)
  end

  # /api, scope "manage_account" WITH CGS needed
  scope "/api", LenraWeb do
    pipe_through([:api, :scope_manage_account, :ensure_cgs_accepted])
    post("/verify", UserController, :validate_user)
    post("/verify/lost", UserController, :resend_registration_token)

    put("/password", UserController, :change_password)
    put("/verify/dev", UserController, :validate_dev)

    get("/webhooks", WebhooksController, :index)
    post("/webhooks", WebhooksController, :api_create)
  end

  # /api, scope "store" & CGS Accepted
  scope "/api", LenraWeb do
    pipe_through([:api, :scope_store, :ensure_cgs_accepted])

    get("/me/apps", AppsController, :get_user_apps)
    get("/me/opened_apps", AppsController, :all_apps_user_opened)
  end

  # /api/apps, scope "manage_apps" & CGS Accepted
  scope "/api/apps", LenraWeb do
    pipe_through([:api, :ensure_cgs_accepted])

    get("/invitations/:id", UserEnvironmentAccessController, :fetch_one)
    post("/invitations/:id", UserEnvironmentAccessController, :accept)

    pipe_through([:scope_manage_apps])

    resources("/", AppsController, only: [:index, :create, :update, :delete])

    # Environments
    get("/:app_id/main_environment", ApplicationMainEnvController, :index)
    resources("/:app_id/environments", EnvsController, only: [:index, :create])
    patch("/:app_id/environments/:env_id", EnvsController, :update)

    # Invitations to env
    resources("/:app_id/environments/:env_id/invitations", UserEnvironmentAccessController, only: [:index, :create])

    # App logo
    get("/:app_id/logo", LogosController, :get_logo)
    put("/:app_id/logo", LogosController, :put_logo)
    get("/:app_id/environments/:env_id/logo", LogosController, :get_logo)
    put("/:app_id/environments/:env_id/logo", LogosController, :put_logo)

    # Builds
    resources("/:app_id/builds", BuildsController, only: [:index, :create])

    # Deployments
    resources("/deployments", DeploymentsController, only: [:create])
    get("/:app_id/deployments", DeploymentsController, :index)
  end

  scope "/api/environments", LenraWeb do
    pipe_through [:api, :scope_manage_apps, :ensure_cgs_accepted]
    post("/:environment_id/oauth2", OAuth2Controller, :create)
    get("/:environment_id/oauth2", OAuth2Controller, :index)
    put("/:environment_id/oauth2/:client_id", OAuth2Controller, :update)
    delete("/:environment_id/oauth2/:client_id", OAuth2Controller, :delete)
  end

  scope "/api/stripe", LenraWeb do
    pipe_through([:api, :scope_manage_account, :ensure_cgs_accepted])
    post("/customers", StripeController, :customer_create)
    get("/subscriptions", StripeController, :index)
    post("/checkout", StripeController, :checkout_create)
    get("/customer_portal", StripeController, :customer_portal)
  end

  # /api resources, scope "resources"
  scope "/api", LenraWeb do
    pipe_through([:api, :scope_resources, :ensure_cgs_accepted])
    ApplicationRunner.Router.resource_route(ResourcesController)
  end

  scope "/", LenraWeb do
    get("/health", HealthController, :index)

    pipe_through([:api])
    post("/apps/:app_uuid/webhooks/:webhook_uuid", WebhooksController, :trigger)
    get("/apps/images/:image_id", LogosController, :get_image_content)
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  # credo:disable-for-next-line Credo.Check.Warning.MixEnv
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through([:fetch_session, :protect_from_forgery])
      live_dashboard("/dashboard", metrics: LenraWeb.Telemetry)
    end
  end
end
