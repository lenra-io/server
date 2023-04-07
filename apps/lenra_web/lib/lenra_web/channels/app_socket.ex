defmodule LenraWeb.AppSocket do
  use ApplicationRunner.AppSocket,
    adapter: LenraWeb.AppAdapter,
    route_channel: LenraWeb.RouteChannel,
    routes_channel: LenraWeb.RoutesChannel
end
