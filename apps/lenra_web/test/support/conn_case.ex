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
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Lenra.Repo)

    unless tags[:async] do
      Sandbox.mode(Lenra.Repo, {:shared, self()})
    end

    map =
      %{conn: Phoenix.ConnTest.build_conn()}
      |> auth_user(tags)
      |> auth_users(tags)
      |> auth_user_with_cgu(tags)

    {:ok, map}
  end

  defp auth_users(map, tags) do
    case tags[:auth_users] do
      roles when is_list(roles) -> Map.put(map, :users, auth_users(roles))
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

  defp auth_user_with_cgu(%{conn: conn} = map, tags) do
    case tags[:auth_user_with_cgu] do
      false -> map
      nil -> map
      true -> Map.put(map, :conn, auth_john_doe_with_cgu(conn))
      role -> Map.put(map, :conn, auth_john_doe_with_cgu(conn, %{"role" => role}))
    end
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

  defp auth_john_doe_with_cgu(conn, params \\ %{}) do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe(params)
    {:ok, cgu} = %{link: "latest", hash: "latesthash", version: "latest"} |> Lenra.Cgu.new() |> Lenra.Repo.insert()

    Lenra.CguServices.accept(cgu.id, user.id)
    conn_user(conn, user)
  end

  defp conn_user(conn, user) do
    {:ok, jwt, _claims} = LenraWeb.Guardian.encode_and_sign(user, %{typ: "access"})

    conn
    |> Plug.Conn.put_req_header("accept", "application/json")
    |> Plug.Conn.put_req_header("authorization", "Bearer " <> jwt)
    |> Plug.Conn.assign(:user, user)
  end
end
