defmodule ApplicationRunner.FakeRouter do
  @moduledoc """
    This is a stub router for unit test only.
  """
  use ApplicationRunner, :router

  require ApplicationRunner.Router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  ApplicationRunner.Router.app_routes()

  scope "/api", ApplicationRunner do
    pipe_through([:api])
    ApplicationRunner.Router.resource_route(FakeResourceController)
  end
end
