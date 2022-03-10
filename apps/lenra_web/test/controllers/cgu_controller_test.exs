defmodule LenraWeb.CguControllerTest do
  @moduledoc """
    Test the `LenraWeb.CguController` module
  """
  use LenraWeb.ConnCase, async: true

  alias Lenra.{Cgu, Repo}

  @valid_cgu1 %{link: "Test", version: "1.0.0", hash: "test"}
  @valid_cgu2 %{link: "Test1", version: "1.1.0", hash: "Test1"}

  describe "Cgu" do
    test "get latest cgu", %{conn: conn} do

      @valid_cgu1 |> Cgu.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      {:ok, %Cgu{} = inserted_cgu1} =
        @valid_cgu2
        |> Cgu.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)
        |> Repo.insert()


      conn = get(conn, Routes.cgu_path(conn, :get_latest_cgu))

      assert json_response(conn, 200) == %{
               "ok" => [%{"code" => 401, "message" => "You are not authenticated"}],
               "success" => false
             }
    end
  end
end
