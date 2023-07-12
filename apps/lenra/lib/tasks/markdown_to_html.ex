defmodule Mix.Tasks.Md2html do
  @shortdoc "Task used to convert a markdown file to a html file"
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

      [file] ->
        case File.exists?(file) do
          true ->
            html =
              file
              |> File.read!()
              |> Earmark.as_html!()

            path = Path.rootname(file) <> ".html"
            # full_html = "#{@before_html} #{@head_html} <body> #{html} </body> #{@after_html}"
            File.write!(path, html)

          false ->
            IO.puts("The "<>file<>" file does not exist or the path is invalid")
        end

      _foo ->
        IO.puts("too much arguments. use mix help md2html for more information")
    end
  end
end
