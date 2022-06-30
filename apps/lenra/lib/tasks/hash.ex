defmodule Mix.Tasks.Hash do
  @shortdoc "Task use to hash a file"

  @moduledoc "The mix hash task

  to use : mix hash file_name

  properties : --algo {desired algorithm to hash the file}"
  use Mix.Task

  @impl true
  def run(args) do
    {opts, paths} = OptionParser.parse!(args, strict: [algo: :string])

    case paths do
      [] ->
        IO.puts("no argument found. use mix help hash for more information")

      [paths] ->
        case File.exists?(paths) do
          true ->
            algo = Keyword.get(opts, :algo, "sha256")

            paths
            |> File.stream!([], 2048)
            |> Enum.reduce(:crypto.hash_init(String.to_atom(algo)), &:crypto.hash_update(&2, &1))
            |> :crypto.hash_final()
            |> Base.encode16()
            |> IO.puts()

          false ->
            IO.puts("The file does not exist or the path is invalid")
        end

      _foo ->
        IO.puts("too much arguments. use mix help hash for more information")
    end
  end
end
