defmodule LenraWeb.CguControllerTest do
  @moduledoc """
    Test the `LenraWeb.CguController` module
  """
  use LenraWeb.ConnCase, async: true

  alias Lenra.Legal.{CGU, UserAcceptCGUVersion}
  alias Lenra.Repo

  @valid_cgu1 %{path: "Test", version: 2, hash: "test"}
  @valid_cgu2 %{path: "Test1", version: 3, hash: "Test1"}
  @valid_cgu3 %{path: "Test2", version: 4, hash: "Test2"}
  @valid_cgu4 %{path: "Test3", version: 5, hash: "Test3"}

  describe "get_latest_cgu" do
    test "test get_latest_cgu with 2 cgu in DB", %{conn: conn} do
      @valid_cgu1 |> CGU.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      @valid_cgu2
      |> CGU.new()
      |> Ecto.Changeset.put_change(:inserted_at, date1)
      |> Repo.insert()

      conn = get(conn, Routes.cgu_path(conn, :get_latest_cgu))

      assert %{"hash" => "Test1", "path" => "Test1", "version" => 3} = json_response(conn, 200)
    end

    test "test get_latest_cgu with 4 cgu in DB", %{conn: conn} do
      @valid_cgu1 |> CGU.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(10, :second) |> DateTime.truncate(:second)

      @valid_cgu2
      |> CGU.new()
      |> Ecto.Changeset.put_change(:inserted_at, date1)
      |> Repo.insert()

      date2 = DateTime.utc_now() |> DateTime.add(20, :second) |> DateTime.truncate(:second)

      @valid_cgu3
      |> CGU.new()
      |> Ecto.Changeset.put_change(:inserted_at, date2)
      |> Repo.insert()

      date3 = DateTime.utc_now() |> DateTime.add(25, :second) |> DateTime.truncate(:second)

      @valid_cgu4
      |> CGU.new()
      |> Ecto.Changeset.put_change(:inserted_at, date3)
      |> Repo.insert()

      conn = get(conn, Routes.cgu_path(conn, :get_latest_cgu))

      assert %{"hash" => "Test3", "path" => "Test3", "version" => 5} = json_response(conn, 200)
    end

    test "test get_latest_cgu without cgu in database", %{conn: conn} do
      Repo.delete_all(CGU)
      conn = get(conn, Routes.cgu_path(conn, :get_latest_cgu))
      assert conn.resp_body == "{\"message\":\"Cgu cannot be found\",\"reason\":\"cgu_not_found\"}"
    end
  end

  describe "accept" do
    @tag auth_user_with_cgu: :dev
    test "with valid cgu_id and user_id", %{conn: conn} do
      date1 = DateTime.utc_now() |> DateTime.add(10, :second) |> DateTime.truncate(:second)

      {:ok, cgu} =
        @valid_cgu2
        |> CGU.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)
        |> Repo.insert()

      conn = post(conn, Routes.cgu_path(conn, :accept, cgu.id), %{"user_id" => conn.assigns[:user].id})

      assert %{"cgu_id" => cgu.id, "user_id" => conn.assigns[:user].id} ==
               json_response(conn, 200)
    end

    @tag auth_user_with_cgu: :dev
    test "with valid cgu_id and user_id but not latest cgu", %{conn: conn} do
      date1 = DateTime.utc_now() |> DateTime.add(10, :second) |> DateTime.truncate(:second)

      {:ok, cgu} =
        @valid_cgu2
        |> CGU.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)
        |> Repo.insert()

      conn = post(conn, Routes.cgu_path(conn, :accept, cgu.id), %{"user_id" => conn.assigns[:user].id})
    end
  end

  describe "user_accepted_latest_cgu" do
    @tag auth_user: :dev
    test "user accepted latest", %{conn: conn} do
      {:ok, cgu} =
        %{hash: "user_accepted_latest_cgu", version: 2, path: "user_accepted_latest_cgu"}
        |> CGU.new()
        |> Lenra.Repo.insert()

      %{cgu_id: cgu.id, user_id: conn.assigns.user.id}
      |> UserAcceptCGUVersion.new()
      |> Lenra.Repo.insert()

      conn = get(conn, Routes.cgu_path(conn, :user_accepted_latest_cgu))

      assert json_response(conn, 200) ==
               true
    end

    @tag auth_user: :dev
    test "user did not accept latest", %{conn: conn} do
      {:ok, _cgu} =
        %{hash: "user_accepted_latest_cgu", version: 2, path: "user_accepted_latest_cgu"}
        |> CGU.new()
        |> Lenra.Repo.insert()

      conn = get(conn, Routes.cgu_path(conn, :user_accepted_latest_cgu))

      assert json_response(conn, 200) ==
               false
    end
  end
end
