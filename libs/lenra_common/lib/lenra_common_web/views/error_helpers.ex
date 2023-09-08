defmodule LenraCommonWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """
  alias LenraCommon.Errors.{BusinessError, DevError, TechnicalError}

  def translate_error(%{errors: []}) do
    raise DevError.exception("Ecto changeset error list should not be empty.")
  end

  # Get errors from ecto Changeset
  def translate_error(%{errors: [err | _rest]}) do
    translate_ecto_error(err)
  end

  def translate_error(%BusinessError{reason: reason, message: message, metadata: metadata}) do
    %{"message" => message, "reason" => reason, "metadata" => metadata}
  end

  def translate_error(%TechnicalError{reason: reason, message: message, metadata: metadata}) do
    %{"message" => message, "reason" => reason, "metadata" => metadata}
  end

  def translate_error(%DevError{reason: reason, message: message, metadata: metadata}) do
    %{"message" => message, "reason" => reason, "metadata" => metadata}
  end

  def translate_error(_err) do
    %{"message" => "An unknown error occured.", "reason" => "unknown_format"}
  end

  defp translate_ecto_error({field, {msg, opts}}) do
    error =
      Enum.reduce(opts, "#{field} #{msg}", fn
        {_key, {:parameterized, _, _}}, acc ->
          acc

        {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
      end)

    %{"message" => error, "reason" => "invalid_" <> to_string(field)}
  end
end
