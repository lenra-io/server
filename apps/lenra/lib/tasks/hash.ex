defmodule Mix.Tasks.Hash do
  @moduledoc "The hash mix task: `mix help hash`"
  use Mix.Task

  @shortdoc "Task for hash a file in sha256"
  def run(args) do
    {opts, paths} = OptionParser.parse!(args, strict: [algo: :string])
    algo = Keyword.get(opts, :algo, "md5")
      File.stream!(paths, [], 2048)
      |> Enum.reduce(:crypto.hash_init(String.to_atom(algo)), &:crypto.hash_update(&2, &1))
      |> :crypto.hash_final()
      |> Base.encode16()
      |> IO.puts()
  end
end
