defmodule Mix.Tasks.Hash do
  @shortdoc "Task use to hash a file"

  @moduledoc "The mix hash task

  to use : mix hash file_name

  properties : --algo {desired algo to hash the file}"
  use Mix.Task

  def run(args) do
    {opts, paths} = OptionParser.parse!(args, strict: [algo: :string])

    case paths do
      [] ->
        IO.puts("no argument found. use mix help hash for more information")

      [paths] ->
        if File.exists?(paths) do
          algo = Keyword.get(opts, :algo, "md5")

          paths
          |> File.stream!([], 2048)
          |> Enum.reduce(:crypto.hash_init(String.to_existing_atom(algo)), &:crypto.hash_update(&2, &1))
          |> :crypto.hash_final()
          |> Base.encode16()
          |> IO.puts()
        else
          IO.puts("The file does not exist or the path is invalid")
        end

      _foo ->
        IO.puts("too much arguments. use mix help hash for more information")
    end
  end
end
