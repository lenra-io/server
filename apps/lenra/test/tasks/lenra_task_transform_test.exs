defmodule Mix.Tasks.TransformTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias Mix.Tasks.Transform

  @path1 "/tmp/transform_test.md"
  @path2 "/tmp/transform_test.html"
  describe "mix tasks" do
    test "transform/1 test transform markdown file to html file" do
      File.write!(@path1, "test")
      Transform.run([@path1])
      assert File.exists?(@path2)
      File.rm!(@path1)
      File.rm(@path2)
    end

    test "transform/1 test mix transform with no argument" do
      hash = capture_io(fn -> Transform.run([]) end) |> String.trim() |> String.downcase()

      assert hash == "no argument found. use mix help transform for more information"
    end

    test "transform/1 test mix transform with too much arguments" do
      hash = capture_io(fn -> Transform.run(["test", "test"]) end) |> String.trim() |> String.downcase()

      assert hash == "too much arguments. use mix help transform for more information"
    end
  end
end
