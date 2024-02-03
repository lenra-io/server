defmodule ApplicationRunner.ChannelCase do
  @moduledoc """
  This module provides a test case template for testing Phoenix channels in the ApplicationRunner application.

  It sets up the necessary aliases, imports, and configurations for testing Phoenix channels.
  The `setup/1` function is used to set up the test environment before each test case.
  The `user/2` function is a helper function for creating a user with specified roles.
  """

  use ExUnit.CaseTemplate

  alias ApplicationRunner.Repo
  alias ApplicationRunner.Contract.{Environment, User}
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      import Phoenix.ChannelTest
      import ApplicationRunner.ChannelCase

      # The default endpoint for testing
      @endpoint ApplicationRunner.FakeEndpoint
    end
  end

  setup tags do
    :ok = Sandbox.checkout(ApplicationRunner.Repo)
    Sandbox.mode(ApplicationRunner.Repo, {:shared, self()})
    start_supervised({Phoenix.PubSub, name: ApplicationRunner.PubSub})

    :telemetry.detach("application_runner.monitor")

    {:ok, %{id: env_id}} = Repo.insert(Environment.new())

    function_name = "env_#{env_id}"

    bypass = Bypass.open(port: 1234)

    Bypass.expect_once(bypass, "GET", "/system/function/#{function_name}", fn conn ->
      Plug.Conn.resp(conn, 200, Jason.encode!(%{name: function_name}))
    end)

    Bypass.expect_once(bypass, "PUT", "/system/functions", fn conn ->
      Plug.Conn.resp(conn, 200, "ok")
    end)

    {user_id, roles} = user(env_id, tags)

    create_socket = fn context ->
      Phoenix.ChannelTest.__connect__(
        ApplicationRunner.FakeEndpoint,
        ApplicationRunner.FakeAppSocket,
        %{connect_result: {:ok, user_id, roles, function_name, context}},
        %{}
      )
    end

    {:ok, create_socket: create_socket, openfaas_bypass: bypass, function_name: function_name}
  end

  defp user(env_id, tags) do
    case tags[:user] do
      nil ->
        {nil, ["guest"]}

      true ->
        create_user(env_id, ["user"])

      roles ->
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

        create_user(env_id, roles)
    end
  end

  defp create_user(_env_id, roles) do
    user =
      User.new(%{"email" => "test@lenra.io"})
      |> Repo.insert!()

    {user.id, roles}
  end
end
