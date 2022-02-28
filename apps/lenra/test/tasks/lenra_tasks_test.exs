defmodule Mix.Tasks.HashTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias Mix.Tasks.Hash

  @path "/tmp/hash_test"
  describe "mix tasks" do
    test "hash/1 test generating hash with mix hash" do

      File.write!(@path, "test")
      hash = capture_io(fn -> Hash.run([@path, "--algo", "sha256"]) end) |> String.trim() |> String.downcase()

      assert hash == "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"
      File.rm(@path)
    end

    test "hash/1 test mix hash with no argument" do

      hash = capture_io(fn -> Hash.run([]) end) |> String.trim() |> String.downcase()

      assert hash == "no argument found. use mix help hash for more information"
    end

    test "hash/1 test mix hash with too much arguments" do

      hash = capture_io(fn -> Hash.run(["test", "test"]) end) |> String.trim() |> String.downcase()

      assert hash == "too much arguments. use mix help hash for more information"
    end
  end
end
