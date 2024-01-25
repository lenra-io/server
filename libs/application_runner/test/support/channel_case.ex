defmodule ApplicationRunner.ChannelCase do
  alias Ecto.Adapters.SQL.Sandbox
  use ExUnit.CaseTemplate

  alias ApplicationRunner.Repo
  alias ApplicationRunner.{Contract, Environment}

  using do
    quote do
      use Phoenix.ChannelTest
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

    {:ok, socket} =
      Phoenix.ChannelTest.__connect__(
        ApplicationRunner.FakeEndpoint,
        ApplicationRunner.FakeAppSocket,
        %{},
        %{}
      )

    socket =
      socket
      |> assign(:env_id, env_id)
      |> assign(:session_id, session_id)
      |> assign(:roles, ["guest"])
      |> user(tags)

    {:ok, socket: socket}
  end

  defp user(%{assigns: assigns} = socket, tags) do
    case tags[:user] do
      nil ->
        socket

      true ->
        set_roles(socket, ["user"])

      roles ->
        set_roles(socket, roles)
    end
  end

  defp set_roles(socket, role) when is_bitstring(role) do
    set_roles(socket, [role])
  end

  defp set_roles(%{assigns: assigns} = socket, roles) when is_list(roles) do
    if Enum.member?(roles, "guest") do
      throw("A user cannot be a guest")
    end

    roles =
      case Enum.member?(roles, "user") do
        true ->
          roles

        false ->
          ["user" | roles]
      end

    socket
    |> assign(
      :roles,
      roles
    )
  end

  defp assign(socket, key, value) do
    socket
    |> Map.put(
      :assigns,
      socket.assigns
      |> Map.put(
        key,
        value
      )
    )
  end
end
