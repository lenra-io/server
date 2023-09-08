defmodule Parallel do
  @moduledoc """
    This module execute task in async.
  """
  def map(enum, func) do
    enum
    |> Enum.map(&Task.async(fn -> func.(&1) end))
    |> Enum.map(&Task.await/1)
  end
end
