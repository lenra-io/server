defmodule ApplicationRunner.FakeRoutesChannel do
  @moduledoc """
  This module provides a fake routes channel for testing purposes.
  """

  use ApplicationRunner.RoutesChannel
end

defmodule ApplicationRunner.FakeRouteChannel do
  @moduledoc """
  This module provides a fake route channel for testing purposes.
  """

  def join("route:" <> route, params, socket) do
    {:ok, socket}
  end

  use ApplicationRunner.RouteChannel
end
