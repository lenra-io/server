defmodule ApplicationRunner.FakeRoutesChannel do
  use ApplicationRunner.RoutesChannel
end

defmodule ApplicationRunner.FakeRouteChannel do
  def join("route:" <> route, params, socket) do
    {:ok, socket}
  end

  use ApplicationRunner.RouteChannel
end
