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

    get "/users/log_in", UserAuthController, :new
    post "/users/register", UserAuthController, :create
    post "/users/log_in", UserAuthController, :login
    get "/users/password/reset", UserAuthController, :reset_password
    get "/users/email/check", UserAuthController, :check_email_page
    post "/users/email/check", UserAuthController, :check_email_token
    post "/users/email/check/new", UserAuthController, :resend_check_email_token
    get "/users/consent", UserConsentController, :index
    post "/users/consent", UserConsentController, :consent
  end

  scope "/", IdentityWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserAuthController, :delete
  end
end
