defmodule Lenra.CguTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Cgu, ServiceGetLatestCgu}

  @valid_cgu1 %{link: "Test", version: "1.0.0", hash: "test"}
  @valid_cgu2 %{link: "Test1", version: "1.1.0", hash: "Test1"}
  @valid_cgu3 %{link: "Test2", version: "1.2.0", hash: "Test2"}
  @valid_cgu4 %{link: "Test3", version: "1.3.0", hash: "Test3"}

  describe "get_latest_cgu" do
    test "insert 2 cgu and check if the service take the latest" do
      {:ok, %Cgu{} = _inserted_cgu} = @valid_cgu1 |> Cgu.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      {:ok, %Cgu{} = inserted_cgu1} =
        @valid_cgu2
        |> Cgu.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)
        |> Repo.insert()

      assert inserted_cgu1 == ServiceGetLatestCgu.get_latest_cgu()
    end

    test "insert 4 cgu and check if the service take the latest" do
      {:ok, %Cgu{} = _inserted_cgu} = @valid_cgu1 |> Cgu.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      {:ok, %Cgu{} = _inserted_cgu1} =
        @valid_cgu2
        |> Cgu.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)
        |> Repo.insert()

      date2 = DateTime.utc_now() |> DateTime.add(8, :second) |> DateTime.truncate(:second)

      {:ok, %Cgu{} = _inserted_cgu2} =
        @valid_cgu3
        |> Cgu.new()
        |> Ecto.Changeset.put_change(:inserted_at, date2)
        |> Repo.insert()

      date3 = DateTime.utc_now() |> DateTime.add(12, :second) |> DateTime.truncate(:second)

      {:ok, %Cgu{} = inserted_cgu3} =
        @valid_cgu4
        |> Cgu.new()
        |> Ecto.Changeset.put_change(:inserted_at, date3)
        |> Repo.insert()

      assert inserted_cgu3 == ServiceGetLatestCgu.get_latest_cgu()
    end
  end
end
