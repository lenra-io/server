defmodule LenraWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use LenraWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox
  alias Lenra.Legal
  alias Lenra.Legal.CGS

  @next_cgs_version 100_000

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import LenraWeb.ConnCase
      import UserTestHelper

      # credo:disable-for-next-line Credo.Check.Readability.AliasAs
      alias LenraWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint LenraWeb.Endpoint

      def create_app(conn) do
        create_app(conn, "test")
      end

      def create_app(conn, name) when is_binary(name) do
        create_app(conn, %{"name" => name})
      end

      def create_app(conn, params) when is_map(params) do
        params =
          Map.merge(
            %{
              "name" => "test",
              "color" => "ffffff",
              "icon" => 12
            },
            params
          )

        post(conn, Routes.apps_path(conn, :create), params)
      end
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Lenra.Repo)

    unless tags[:async] do
      Sandbox.mode(Lenra.Repo, {:shared, self()})
    end

    map =
      %{conn: Phoenix.ConnTest.build_conn()}
      |> create_hydra_bypass()
      |> add_hydra_introspect_stub()
      |> auth_user(tags)
      |> auth_users(tags)
      |> auth_user_with_cgs(tags)
      |> auth_users_with_cgs(tags)

    {:ok, map}
  end

  defp create_hydra_bypass(map) do
    hydra_bypass = Bypass.open(port: 4405)

    Map.put(map, :hydra_bypass, hydra_bypass)
  end

  defp add_hydra_introspect_stub(%{hydra_bypass: hydra_bypass} = map) do
    Bypass.stub(hydra_bypass, "POST", "/admin/oauth2/introspect", &hydra_introspect_response/1)

    map
  end

  def hydra_introspect_response(conn) do
    conn = parse_body_params(conn)
    %{"scope" => _scope, "token" => token} = conn.body_params
    resp = decode_fake_token(token)

    Plug.Conn.resp(conn, 200, Jason.encode!(resp))
  end

  defp parse_body_params(conn) do
    options = [
      parsers: [:urlencoded, :json],
      json_decoder: Jason
    ]

    opts = Plug.Parsers.init(options)
    Plug.Parsers.call(conn, opts)
  end

  defp auth_users(map, tags) do
    case tags[:auth_users] do
      roles when is_list(roles) -> Map.put(map, :users, auth_users(roles))
      _roles -> Map.put(map, :users, [])
    end
  end

  defp auth_users_with_cgs(map, tags) do
    case tags[:auth_users_with_cgs] do
      roles when is_list(roles) -> Map.put(map, :users, auth_users_with_cgs(roles))
      _roles -> Map.put(map, :users, [])
    end
  end

  defp auth_user(%{conn: conn} = map, tags) do
    case tags[:auth_user] do
      false -> map
      nil -> map
      true -> Map.put(map, :conn, auth_john_doe(conn))
      role -> Map.put(map, :conn, auth_john_doe(conn, %{"role" => role}))
    end
  end

  defp auth_user_with_cgs(%{conn: conn} = map, tags) do
    case tags[:auth_user_with_cgs] do
      false -> map
      nil -> map
      true -> Map.put(map, :conn, auth_john_doe_with_cgs(conn))
      role -> Map.put(map, :conn, auth_john_doe_with_cgs(conn, %{"role" => role}))
    end
  end

  defp auth_users_with_cgs(users_role) do
    {:ok, cgs} = %{path: "latest", hash: "latesthash", version: @next_cgs_version} |> CGS.new() |> Lenra.Repo.insert()

    users_role
    |> Enum.with_index()
    |> Enum.map(fn {role, idx} ->
      conn = Phoenix.ConnTest.build_conn()
      {:ok, %{inserted_user: user}} = UserTestHelper.register_user_nb(idx, role)

      Legal.accept_cgs(cgs.id, user.id)
      conn_user(conn, user)
    end)
  end

  defp auth_users(users_role) do
    users_role
    |> Enum.with_index()
    |> Enum.map(fn {role, idx} ->
      conn = Phoenix.ConnTest.build_conn()
      {:ok, %{inserted_user: user}} = UserTestHelper.register_user_nb(idx, role)
      conn_user(conn, user)
    end)
  end

  defp auth_john_doe(conn, params \\ %{}) do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe(params)
    conn_user(conn, user)
  end

  defp auth_john_doe_with_cgs(conn, params \\ %{}) do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe(params)

    {:ok, cgs} = %{path: "latest", hash: "latesthash", version: @next_cgs_version} |> CGS.new() |> Lenra.Repo.insert()

    Legal.accept_cgs(cgs.id, user.id)
    conn_user(conn, user)
  end

  defp conn_user(conn, user) do
    # Create a fake token that contains the "introspect" return value directly
    token = create_fake_token(user.id)

    conn
    |> Plug.Conn.put_req_header("accept", "application/json")
    |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)
    |> Plug.Conn.assign(:user, user)
  end

  defp create_fake_token(user_id) do
    %{"sub" => user_id, "active" => true}
    |> Jason.encode!()
    |> Base.encode64()
  end

  defp decode_fake_token(token) do
    token
    |> Base.decode64!()
    |> Jason.decode!()
  end
end
