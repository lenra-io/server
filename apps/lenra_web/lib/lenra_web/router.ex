defmodule LenraWeb.Router do
  use LenraWeb, :router

  alias LenraWeb.{Pipeline, Plug}

  require ApplicationRunner.Router

  ApplicationRunner.Router.app_routes()

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :runner do
    plug(Plug.VerifySecret)
  end

  pipeline :ensure_auth do
    plug(Pipeline.EnsureAuthed)
  end

  pipeline :ensure_resource_auth do
    plug(Pipeline.EnsureAuthedQueryParams)
  end

  pipeline :ensure_auth_refresh do
    plug(Pipeline.RefreshToken)
  end

  pipeline :ensure_cgu_accepted do
    plug(Plug.VerifyCgu)
  end

  scope "/auth", LenraWeb do
    pipe_through(:api)
    post("/register", UserController, :register)
    post("/login", UserController, :login)
    post("/password/lost", UserController, :send_lost_password_code)
    put("/password/lost", UserController, :change_lost_password)

    pipe_through(:ensure_auth_refresh)
    post("/logout", UserController, :logout)

    pipe_through([:ensure_cgu_accepted])
    post("/refresh", UserController, :refresh_token)
  end

  scope "/runner", LenraWeb do
    pipe_through([:api, :runner])
    put("/builds/:id", RunnerController, :update_build)
  end

  scope "/api", LenraWeb do
    pipe_through([:api])
    get("/cgu/latest", CguController, :get_latest_cgu)

    pipe_through([:ensure_auth])
    post("/cgu/:cgu_id/accept", CguController, :accept)
    get("/cgu/me/accepted_latest", CguController, :user_accepted_latest_cgu)

    pipe_through([:ensure_cgu_accepted])
    post("/verify", UserController, :validate_user)
    resources("/apps", AppsController, only: [:index, :create, :update, :delete])
    get("/apps/:app_id/main_environment", ApplicationMainEnvController, :index)
    resources("/apps/:app_id/environments", EnvsController, only: [:index, :create])
    patch("/apps/:app_id/environments/:env_id", EnvsController, :update)

    resources("/apps/:app_id/environments/:env_id/invitations", UserEnvironmentAccessController, only: [:index, :create])

    get("/apps/invitations/:uuid", UserEnvironmentAccessController, :fetch_one)
    post("/apps/invitations/:uuid", UserEnvironmentAccessController, :accept)

    resources("/apps/:app_id/builds", BuildsController, only: [:index, :create])

    resources("/apps/deployments", DeploymentsController, only: [:create])
    put("/password", UserController, :change_password)
    put("/verify/dev", UserController, :validate_dev)

    get("/me/apps", AppsController, :get_user_apps)
    get("/me/opened_apps", AppsController, :all_apps_user_opened)

    get("/webhooks", WebhooksController, :index)
    post("/webhooks", WebhooksController, :api_create)
  end

  scope "/api", LenraWeb do
    pipe_through([:api, :ensure_resource_auth, :ensure_cgu_accepted])
    ApplicationRunner.Router.resource_route(ResourcesController)
  end

  scope "/", LenraWeb do
    get("/health", HealthController, :index)
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
