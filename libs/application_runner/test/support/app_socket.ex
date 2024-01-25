defmodule ApplicationRunner.FakeAppSocket do
  use Phoenix.Socket

  ## Channels
  channel("route:*", ApplicationRunner.RouteChannel)
  channel("routes", ApplicationRunner.RoutesChannel)

  @impl true
  def connect(_params, socket, _connect_info) do
    IO.inspect("FakeAppSocket connect")
    {:ok, socket}
  end

  @impl true
  def id(socket), do: nil
end
