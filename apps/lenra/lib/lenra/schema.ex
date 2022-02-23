defmodule Lenra.Schema do
  @moduledoc """
    Define a base schema to be used.
    This schema will define some default configuration (timestamp to :utc_datetime)
    Use this schema to apply the configuration
  """
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @timestamps_opts [type: :utc_datetime]
    end
  end
end
