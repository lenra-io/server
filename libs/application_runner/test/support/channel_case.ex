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
      %Phoenix.Socket{assigns: %{env_id: env_id, session_id: session_id, roles: ["guest"]}}
      |> user(tags)

    {:ok, socket: socket, env_id: env_id, session_id: session_id}
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
    roles = case Enum.member?(roles, "user") do
      true ->
        roles

      false ->
        ["user" | roles]
    end
    socket
    |> Map.put(
      :assigns,
      assigns
      |> Map.put(
        :roles,
        roles
      )
    )
  end
end
