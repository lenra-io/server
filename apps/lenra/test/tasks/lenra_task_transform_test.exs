defmodule Mix.Tasks.Md2htmlTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias Mix.Tasks.Md2html

  @path1 "/tmp/md2html_test.md"
  @path2 "/tmp/md2html_test.html"
  describe "mix tasks" do
    test "md2html/1 test md2html markdown file to html file" do
      File.write!(@path1, "test")
      Md2html.run([@path1])
      assert File.exists?(@path2)
      File.rm!(@path1)
      File.rm!(@path2)
    end

    test "md2html/1 test content of html file after mix md2html" do
      head_html = "<head><meta charset=\"utf-8\"><title>CGU</title></head>"

      before_html = "<!doctype html><html>"

      after_html = "</html>"

      html = " <body> <p>\ntest</p>\n </body> "

      full_html = "#{before_html} #{head_html}#{html}#{after_html}"

      File.write!(@path1, "test")
      Md2html.run([@path1])
      assert File.read!(@path2) == full_html
      File.rm!(@path1)
      File.rm!(@path2)
    end

    test "md2html/1 test mix md2html with no argument" do
      hash = capture_io(fn -> Md2html.run([]) end)

      hash1 =
        hash
        |> String.trim()
        |> String.downcase()

      assert hash1 == "no argument found. use mix help md2html for more information"
    end

    test "md2html/1 test mix md2html with too much arguments" do
      hash = capture_io(fn -> Md2html.run(["test", "test"]) end)
      hash1 = hash |> String.trim() |> String.downcase()

      assert hash1 == "too much arguments. use mix help md2html for more information"
    end
  end
end
