defmodule ApplicationRunner.ChannelCase do
  alias Ecto.Adapters.SQL.Sandbox
  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with channels
      import Phoenix.ChannelTest
      import ApplicationRunner.ChannelCase

      # The default endpoint for testing
      @endpoint ApplicationRunner.FakeEndpoint
    end
  end

  setup tags do
    start_supervised({Phoenix.PubSub, name: ApplicationRunner.PubSub})
    :ok = Sandbox.checkout(ApplicationRunner.Repo)

    unless tags[:async] do
      Sandbox.mode(ApplicationRunner.Repo, {:shared, self()})
    end
    :ok
  end
end
