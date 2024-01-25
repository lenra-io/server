defmodule ApplicationRunner.ChannelCase do
  alias Ecto.Adapters.SQL.Sandbox
  use ExUnit.CaseTemplate

  alias ApplicationRunner.Repo
  alias ApplicationRunner.{Contract, Environment}

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

    {:ok, %{id: env_id}} = Repo.insert(Contract.Environment.new())
    session_id = :rand.uniform(1_000_000)

    socket =
      %Phoenix.Socket{ assigns: %{env_id: env_id, session_id: session_id, roles: ["guest"]}}
      |> user(tags)

    {:ok, socket: socket, env_id: env_id, session_id: session_id}
  end

  defp user(%{assigns: assigns} = socket, tags) do
    IO.inspect(socket)

    case tags[:user] do
      roles when is_list(roles) ->
        Map.put(
          socket,
          :assigns,
          Map.put(
            assigns,
            :roles,
            case roles do
              [] -> ["user"]
              _ -> roles
            end
          )
        )

      _roles ->
        socket
    end
  end
end
