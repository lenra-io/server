defmodule Mix.Tasks.Md2html do
  @shortdoc "Task used to md2html a markdown file to a html file"
  @moduledoc "The mix md2html task\n
  To use : mix md2html file_name"

  use Mix.Task

  @head_html "<head><meta charset=\"utf-8\"><title>CGU</title></head>"
  @before_html "<!doctype html><html>"
  @after_html "</html>"

  def run(args) do
    case args do
      [] ->
        IO.puts("no argument found. use mix help md2html for more information")

      [args] ->
        case File.exists?(args) do
          true ->
            html =
              args
              |> File.read!()
              |> Earmark.as_html!()

            path = Path.rootname(args) <> ".html"
            full_html = "#{@before_html} #{@head_html} <body> #{html} </body> #{@after_html}"
            File.write!(path, full_html)

          false ->
            IO.puts("The file does not exist or the path is invalid")
        end

      _foo ->
        IO.puts("too much arguments. use mix help md2html for more information")
    end
  end
end