defmodule LenraWeb.Router do
  use LenraWeb, :router

  alias Lenra.Guardian.{
    EnsureAuthenticatedPipeline,
    EnsureAuthenticatedQueryParamsPipeline,
    RefreshPipeline
  }

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :runner do
    plug(Lenra.Plug.VerifySecret)
  end

  pipeline :ensure_auth do
    plug(EnsureAuthenticatedPipeline)
  end

  pipeline :ensure_resource_auth do
    plug(EnsureAuthenticatedQueryParamsPipeline)
  end

  pipeline :ensure_auth_refresh do
    plug(RefreshPipeline)
  end

  pipeline :ensure_cgu_accepted do
    plug(LenraWeb.Plugs.CheckCguPlug)
  end

  scope "/cgu", LenraWeb do
    pipe_through([:api])
    get("/latest", CguController, :get_latest_cgu)
  end

  scope "/auth", LenraWeb do
    pipe_through(:api)
    post("/register", UserController, :register)
    post("/login", UserController, :login)
    post("/password/lost", UserController, :password_lost_code)
    put("/password/lost", UserController, :password_lost_modification)

    pipe_through(:ensure_auth_refresh)
    post("/logout", UserController, :logout)
    post("/verify", UserController, :validate_user)

    pipe_through([:ensure_cgu_accepted])
    post("/refresh", UserController, :refresh)
  end

  scope "/runner", LenraWeb do
    pipe_through([:api, :runner])
    put("/builds/:id", RunnerController, :update_build)
  end

  scope "/api", LenraWeb do
    pipe_through([:api, :ensure_auth])
    post("/cgu/:cgu_id/accept", CguController, :accept)

    pipe_through([:ensure_cgu_accepted])
    resources("/apps", AppsController, only: [:index, :create, :delete])
    get("/apps/:app_id/main_environment", ApplicationMainEnvController, :index)
    resources("/apps/:app_id/environments", EnvsController, only: [:index, :create])
    patch("/apps/:app_id/environments/:env_id", EnvsController, :update)

    resources("/apps/:app_id/environments/:env_id/invitations", UserEnvironmentAccessController, only: [:index, :create])

    resources("/apps/:app_id/builds", BuildsController, only: [:index, :create])

    resources("/apps/deployments", DeploymentsController, only: [:create])
    put("/password", UserController, :password_modification)
    put("/verify/dev", UserController, :validate_dev)
    get("/me/apps", AppsController, :get_user_apps)
    get("/me/cgu/accepted_latest", CguController, :user_accepted_latest_cgu)
  end

  scope "/api", LenraWeb do
    pipe_through([:api, :ensure_resource_auth, :ensure_cgu_accepted])
    get("/apps/:service_name/resources/:resource", ResourcesController, :get_app_resource)
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
