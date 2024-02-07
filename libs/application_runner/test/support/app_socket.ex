defmodule ApplicationRunner.FakeAppSocket do
  use ApplicationRunner.AppSocket,
    adapter: ApplicationRunner.FakeAppAdapter,
    route_channel: ApplicationRunner.RouteChannel,
    routes_channel: ApplicationRunner.RoutesChannel
end
