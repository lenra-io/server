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

  describe "Cgu" do
    test "test get latest cgu with 2 cgu in DB", %{conn: conn} do
      @valid_cgu1 |> Cgu.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      @valid_cgu2
      |> Cgu.new()
      |> Ecto.Changeset.put_change(:inserted_at, date1)
      |> Repo.insert()

      conn = get(conn, Routes.cgu_path(conn, :get_latest_cgu))

      assert json_response(conn, 200) == %{
               "data" => %{"latest_cgu" => %{"hash" => "Test1", "link" => "Test1", "version" => "1.1.0"}},
               "success" => true
             }
    end

    test "test get latest cgu with 4 cgu in DB", %{conn: conn} do
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

      assert json_response(conn, 200) == %{
               "data" => %{"latest_cgu" => %{"hash" => "Test3", "link" => "Test3", "version" => "1.3.0"}},
               "success" => true
             }
    end
  end
end
