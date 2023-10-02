defmodule IdentityWeb.Router do
  use IdentityWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {IdentityWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  ## OAuth Authentication routes
  scope "/", IdentityWeb do
    pipe_through [:browser]

    get "/users/auth", UserAuthController, :new
    get "/users/register", UserAuthController, :register_page
    post "/users/register", UserAuthController, :register
    get "/users/login", UserAuthController, :login_page
    post "/users/login", UserAuthController, :login
    get "/users/login/cancel", UserAuthController, :cancel_login
    get "/users/email/check", UserAuthController, :check_email_page
    post "/users/email/check", UserAuthController, :check_email_token
    post "/users/email/check/new", UserAuthController, :resend_check_email_token
    get "/users/cgs/validation", UserAuthController, :validate_cgs_page
    post "/users/cgs/validation", UserAuthController, :validate_cgs
    get "/users/password/lost", UserAuthController, :lost_password_enter_email
    post("/users/password/lost", UserAuthController, :send_lost_password_code)
    put("/users/password/lost", UserAuthController, :change_lost_password)
    get "/users/consent", UserConsentController, :index
    post "/users/consent", UserConsentController, :consent
  end

  scope "/", IdentityWeb do
    pipe_through [:browser]

    get "/users/logout", UserAuthController, :logout
  end
end
