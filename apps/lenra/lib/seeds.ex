defmodule Lenra.Seeds do
  @moduledoc """
  Module to populate the database. The "run" function must be idempotent.
  """

  def run do
    generate_cgu()
  end

  def generate_cgu do
    Application.app_dir(:lenra_web, "/priv/static/cgu/CGU_fr_*.md")
    |> Path.wildcard()
    |> Enum.each(fn path ->
      "CGU_fr_" <> version = path |> Path.basename(".md")
      Lenra.Legal.add_cgu(path, version)
    end)
  end
end
