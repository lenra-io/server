defmodule LenraWeb.CguControllerTest do
  @moduledoc """
    Test the `LenraWeb.CguController` module
  """
  use LenraWeb.ConnCase, async: true

  alias Lenra.{Cgu, Repo}

  @valid_cgu1 %{link: "Test", version: "1.0.0", hash: "test"}
  @valid_cgu2 %{link: "Test1", version: "1.1.0", hash: "Test1"}
  @valid_cgu3 %{link: "Test2", version: "1.2.0", hash: "Test2"}
  @valid_cgu4 %{link: "Test3", version: "1.3.0", hash: "Test3"}

  describe "get_latest_cgu" do
    test "test get_latest_cgu with 2 cgu in DB", %{conn: conn} do
      @valid_cgu1 |> Cgu.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      @valid_cgu2
      |> Cgu.new()
      |> Ecto.Changeset.put_change(:inserted_at, date1)
      |> Repo.insert()

      conn = get(conn, Routes.cgu_path(conn, :get_latest_cgu))

      assert %{
               "data" => %{"latest_cgu" => %{"hash" => "Test1", "link" => "Test1", "version" => "1.1.0"}},
               "success" => true
             } = json_response(conn, 200)
    end

    test "test get_latest_cgu with 4 cgu in DB", %{conn: conn} do
      @valid_cgu1 |> Cgu.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      @valid_cgu2
      |> Cgu.new()
      |> Ecto.Changeset.put_change(:inserted_at, date1)
      |> Repo.insert()

      date2 = DateTime.utc_now() |> DateTime.add(8, :second) |> DateTime.truncate(:second)

      @valid_cgu3
      |> Cgu.new()
      |> Ecto.Changeset.put_change(:inserted_at, date2)
      |> Repo.insert()

      date3 = DateTime.utc_now() |> DateTime.add(12, :second) |> DateTime.truncate(:second)

      @valid_cgu4
      |> Cgu.new()
      |> Ecto.Changeset.put_change(:inserted_at, date3)
      |> Repo.insert()

      conn = get(conn, Routes.cgu_path(conn, :get_latest_cgu))

      assert %{
               "data" => %{"latest_cgu" => %{"hash" => "Test3", "link" => "Test3", "version" => "1.3.0"}},
               "success" => true
             } = json_response(conn, 200)
    end

    test "test get_latest_cgu without cgu in database", %{conn: conn} do
      conn = get(conn, Routes.cgu_path(conn, :get_latest_cgu))

      assert json_response(conn, 404) == %{
               "errors" => [%{"code" => 404, "message" => "Not Found."}],
               "success" => false
             }
    end
  end

  describe "accept" do
    @tag auth_user_with_cgu: :dev
    test "with valid cgu_id and user_id", %{conn: conn} do
      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      {:ok, cgu} =
        @valid_cgu2
        |> Cgu.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)
        |> Repo.insert()

      conn = post(conn, Routes.cgu_path(conn, :accept, cgu.id), %{"user_id" => conn.assigns[:user].id})

      assert %{
               "data" => %{"accepted_cgu" => %{"cgu_id" => cgu.id, "user_id" => conn.assigns[:user].id}},
               "success" => true
             } == json_response(conn, 200)
    end

    @tag auth_user_with_cgu: :dev
    test "with valid cgu_id and user_id but not latest cgu", %{conn: conn} do
      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      {:ok, cgu} =
        @valid_cgu2
        |> Cgu.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)
        |> Repo.insert()

      conn = post(conn, Routes.cgu_path(conn, :accept, cgu.id), %{"user_id" => conn.assigns[:user].id})

      assert %{"success" => true} = json_response(conn, 200)
    end
  end

  describe "user_accepted_latest_cgu" do
    @tag auth_user: :dev
    test "user accepted latest", %{conn: conn} do
      {:ok, cgu} =
        %{hash: "user_accepted_latest_cgu", version: "user_accepted_latest_cgu", link: "user_accepted_latest_cgu"}
        |> Lenra.Cgu.new()
        |> Lenra.Repo.insert()

      %{cgu_id: cgu.id, user_id: conn.assigns.user.id}
      |> Lenra.UserAcceptCguVersion.new()
      |> Lenra.Repo.insert()

      conn = get(conn, Routes.cgu_path(conn, :user_accepted_latest_cgu))

      assert json_response(conn, 200) == %{
               "data" => %{"user_accepted_latest_cgu" => true},
               "success" => true
             }
    end

    @tag auth_user: :dev
    test "user did not accept latest", %{conn: conn} do
      {:ok, _cgu} =
        %{hash: "user_accepted_latest_cgu", version: "user_accepted_latest_cgu", link: "user_accepted_latest_cgu"}
        |> Lenra.Cgu.new()
        |> Lenra.Repo.insert()

      conn = get(conn, Routes.cgu_path(conn, :user_accepted_latest_cgu))

      assert json_response(conn, 200) == %{
               "data" => %{"user_accepted_latest_cgu" => false},
               "success" => true
             }
    end
  end
end
