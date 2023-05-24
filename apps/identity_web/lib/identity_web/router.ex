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

  scope "/", IdentityWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", IdentityWeb do
  #   pipe_through :api
  # end

  # # Enables the Swoosh mailbox preview in development.
  # #
  # # Note that preview only shows emails that were sent by the same
  # # node running the Phoenix server.
  # if Mix.env() == :dev do
  #   scope "/dev" do
  #     pipe_through :browser

  #     forward "/mailbox", Plug.Swoosh.MailboxPreview
  #   end
  # end

  ## Authentication routes

  scope "/", IdentityWeb do
    pipe_through [:browser]

    get "/users/log_in", UserAuthController, :new
    post "/users/register", UserAuthController, :create
    post "/users/log_in", UserAuthController, :login
  end

  scope "/", IdentityWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserAuthController, :delete
  end
end
