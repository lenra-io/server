defmodule Mix.Tasks.Hash do
  @shortdoc "Task use to hash a file"

  @moduledoc "The mix hash task

  to use : mix hash file_name

  properties : --algo {desired algorithm to hash the file}"
  use Mix.Task
  alias Lenra.Utils

  @impl true
  def run(args) do
    {opts, path} = OptionParser.parse!(args, strict: [algo: :string])

    case path do
      [] ->
        IO.puts("no argument found. use mix help hash for more information")

      [path] ->
        case File.exists?(path) do
          true ->
            # credo:disable-for-next-line
            algo = String.to_atom(Keyword.get(opts, :algo, "sha256"))

            path
            |> Utils.hash_file(algo)
            |> IO.puts()

          false ->
            IO.puts("The file does not exist or the path is invalid")
        end

      _foo ->
        IO.puts("too much arguments. use mix help hash for more information")
    end
  end
end
