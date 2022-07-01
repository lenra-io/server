defmodule LenraWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  alias Lenra.Errors.{BusinessError, DevError, TechnicalError}

  def translate_error(%Ecto.Changeset{errors: errors}) do
    translate_ecto_error(Enum.at(errors, 0))
  end

  def translate_error(%BusinessError{} = err) do
    Lenra.Errors.message(err)
  end

  def translate_error(%TechnicalError{} = err) do
    Lenra.Errors.message(err)
  end

  def translate_error(%DevError{} = err) do
    Lenra.Errors.message(err)
  end

  def translate_error(_err) do
    "An unknown error occured."
  end

  def translate_ecto_error({field, {msg, opts}}) do
    error =
      Enum.reduce(opts, "#{field} #{msg}", fn
        {_key, {:parameterized, _, _}}, acc -> acc
        {key, value}, acc -> String.replace(acc, "%{#{key}}", to_string(value))
      end)

    error
  end
end
