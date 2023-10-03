defmodule Lenra.Seeds do
  @moduledoc """
  Module to populate the database. The "run" function must be idempotent.
  """

  def run do
    generate_cgs()
  end

  def generate_cgs do
    Application.app_dir(:identity_web, "/priv/static/cgs/CGS_fr_*.md")
    |> Path.wildcard()
    |> Enum.each(fn path ->
      "CGS_fr_" <> version = path |> Path.basename(".md")
      Lenra.Legal.add_cgs(path, version)
    end)
  end
end
