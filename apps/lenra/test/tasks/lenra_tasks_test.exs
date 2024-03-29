defmodule Mix.Tasks.HashTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias Mix.Tasks.Hash

  @path "/tmp/hash_test"
  @path2 "/tmp/hash_test2"
  describe "mix tasks" do
    test "hash/1 test generating hash with mix hash" do
      File.write!(@path, "test")
      hash = capture_io(fn -> Hash.run([@path, "--algo", "sha256"]) end)

      hash1 =
        hash
        |> String.trim()
        |> String.downcase()

      assert hash1 == "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"
      File.rm(@path)
    end

    test "hash/1 test mix hash with no argument" do
      hash = capture_io(fn -> Hash.run([]) end)

      hash1 =
        hash
        |> String.trim()
        |> String.downcase()

      assert hash1 == "no argument found. use mix help hash for more information"
    end

    test "hash/1 test mix hash with too much arguments" do
      hash = capture_io(fn -> Hash.run(["test", "test"]) end)

      hash1 =
        hash
        |> String.trim()
        |> String.downcase()

      assert hash1 == "too much arguments. use mix help hash for more information"
    end

    test "hash/1 test mix hash with invlaid path" do
      hash = capture_io(fn -> Hash.run([@path2]) end)

      hash1 =
        hash
        |> String.trim()

      assert hash1 == "The file does not exist or the path is invalid"
    end
  end
end
