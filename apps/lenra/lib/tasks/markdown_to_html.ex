defmodule Mix.Tasks.Transform do
  @moduledoc "The mix transform task\n
  To use : mix transform file_name"
  use Mix.Task

  @shortdoc "Task used to transform a markdown file to a html file"
  def run(args) do
    case args do
      [] ->
        IO.puts("no argument found. use mix help transform for more information")

      [args] ->
        html =
          File.read!(args)
          |> Earmark.as_html!()

        path = Path.rootname(args) <> ".html"
        File.write!(path, html)

      _ ->
        IO.puts("too much arguments. use mix help transform for more information")
    end
  end
end
