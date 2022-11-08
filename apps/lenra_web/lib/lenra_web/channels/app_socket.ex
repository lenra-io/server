defmodule LenraWeb.AppSocket do
  use ApplicationRunner.AppSocket,
    adapter: LenraWeb.AppAdapter,
    route_channel: LenraWeb.RouteChannel
end
