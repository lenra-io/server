defmodule LenraWeb.CgsControllerTest do
  @moduledoc """
    Test the `LenraWeb.CgsController` module
  """
  use LenraWeb.ConnCase, async: true

  alias Lenra.Legal.{CGS, UserAcceptCGSVersion}
  alias Lenra.Repo

  @valid_cgs1 %{path: "Test", version: 2, hash: "test"}
  @valid_cgs2 %{path: "Test1", version: 3, hash: "Test1"}
  @valid_cgs3 %{path: "Test2", version: 4, hash: "Test2"}
  @valid_cgs4 %{path: "Test3", version: 5, hash: "Test3"}

  describe "get_latest_cgs" do
    test "test get_latest_cgs with 2 cgs in DB", %{conn: conn} do
      @valid_cgs1 |> CGS.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      @valid_cgs2
      |> CGS.new()
      |> Ecto.Changeset.put_change(:inserted_at, date1)
      |> Repo.insert()

      conn = get(conn, Routes.cgs_path(conn, :get_latest_cgs))

      assert %{"hash" => "Test1", "path" => "Test1", "version" => 3} = json_response(conn, 200)
    end

    test "test get_latest_cgs with 4 cgs in DB", %{conn: conn} do
      @valid_cgs1 |> CGS.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(10, :second) |> DateTime.truncate(:second)

      @valid_cgs2
      |> CGS.new()
      |> Ecto.Changeset.put_change(:inserted_at, date1)
      |> Repo.insert()

      date2 = DateTime.utc_now() |> DateTime.add(20, :second) |> DateTime.truncate(:second)

      @valid_cgs3
      |> CGS.new()
      |> Ecto.Changeset.put_change(:inserted_at, date2)
      |> Repo.insert()

      date3 = DateTime.utc_now() |> DateTime.add(25, :second) |> DateTime.truncate(:second)

      @valid_cgs4
      |> CGS.new()
      |> Ecto.Changeset.put_change(:inserted_at, date3)
      |> Repo.insert()

      conn = get(conn, Routes.cgs_path(conn, :get_latest_cgs))

      assert %{"hash" => "Test3", "path" => "Test3", "version" => 5} = json_response(conn, 200)
    end

    test "test get_latest_cgs without cgs in database", %{conn: conn} do
      Repo.delete_all(CGS)
      conn = get(conn, Routes.cgs_path(conn, :get_latest_cgs))

      assert conn.resp_body ==
               "{\"message\":\"Cgs cannot be found\",\"metadata\":{},\"reason\":\"cgs_not_found\"}"
    end
  end

  describe "accept" do
    @tag auth_user_with_cgs: :dev
    test "with valid cgs_id and user_id", %{conn: conn} do
      date1 = DateTime.utc_now() |> DateTime.add(10, :second) |> DateTime.truncate(:second)

      {:ok, cgs} =
        @valid_cgs2
        |> CGS.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)
        |> Repo.insert()

      conn = post(conn, Routes.cgs_path(conn, :accept, cgs.id), %{"user_id" => conn.assigns[:user].id})

      assert %{"cgs_id" => cgs.id, "user_id" => conn.assigns[:user].id} ==
               json_response(conn, 200)
    end

    @tag auth_user_with_cgs: :dev
    test "with valid cgs_id and user_id but not latest cgs", %{conn: conn} do
      date1 = DateTime.utc_now() |> DateTime.add(10, :second) |> DateTime.truncate(:second)

      {:ok, cgs} =
        @valid_cgs2
        |> CGS.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)
        |> Repo.insert()

      post(conn, Routes.cgs_path(conn, :accept, cgs.id), %{"user_id" => conn.assigns[:user].id})
    end
  end

  describe "user_accepted_latest_cgs" do
    @tag auth_user: :dev
    test "user accepted latest", %{conn: conn} do
      {:ok, cgs} =
        %{hash: "user_accepted_latest_cgs", version: 2, path: "user_accepted_latest_cgs"}
        |> CGS.new()
        |> Lenra.Repo.insert()

      %{cgs_id: cgs.id, user_id: conn.assigns.user.id}
      |> UserAcceptCGSVersion.new()
      |> Lenra.Repo.insert()

      conn = get(conn, Routes.cgs_path(conn, :user_accepted_latest_cgs))

      assert json_response(conn, 200) ==
               %{"accepted" => true}
    end

    @tag auth_user: :dev
    test "user did not accept latest", %{conn: conn} do
      {:ok, _cgs} =
        %{hash: "user_accepted_latest_cgs", version: 2, path: "user_accepted_latest_cgs"}
        |> CGS.new()
        |> Lenra.Repo.insert()

      conn = get(conn, Routes.cgs_path(conn, :user_accepted_latest_cgs))

      assert json_response(conn, 200) ==
               %{"accepted" => false}
    end
  end
end
