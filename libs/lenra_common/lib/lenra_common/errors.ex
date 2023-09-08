defmodule LenraCommon.Errors do
  @moduledoc """
    LenraCommon.Errors manage common errors.
  """
  require Logger

  @deprecated "Use format_error_with_stacktrace/1 instead"
  def log(error) do
    error
    |> format_error_with_stacktrace()
    |> Logger.error()
  end

  @doc """
  Formats error to string.
  """
  def format_error(error) when is_struct(error) do
    error.message
  end

  def format_error(error) do
    to_string(error)
  end

  @doc """
  Formats error with stacktrace to string.
  """
  def format_error_with_stacktrace(error) do
    [
      format_error(error),
      "\n",
      format_stacktrace(Process.info(self(), :current_stacktrace))
    ]
    |> Enum.join()
  end

  @doc """
  Formats stacktrace to string.
  """
  def format_stacktrace({_, stacktrace}) do
    stacktrace
    |> Enum.slice(2..-1)
    |> Enum.map_join("\n", &format_stacktrace_line/1)
  end

  defp format_stacktrace_line({module, method, argNum, [file: file, line: line]}) do
    "\t#{file}:#{line} #{module}.#{method}/#{argNum}"
  end
end
