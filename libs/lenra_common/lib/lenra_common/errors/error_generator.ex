defmodule LenraCommon.Errors.ErrorGenerator do
  @moduledoc """
    LenraCommon.Errors.ErrorGenerator allows to generate two functions following a list of errors.
    The first function returns the error structure and the second returns the `{:error, _error_struct}` tuple.
  """
  defmacro __using__(opts) do
    errors = Keyword.get(opts, :errors, [])
    inherit = Keyword.get(opts, :inherit, false)
    module = Keyword.fetch!(opts, :module)

    quote do
      import LenraCommon.Errors.ErrorGenerator

      all_errors =
        if unquote(inherit),
          do: unquote(errors) ++ unquote(module).__errors__(),
          else: unquote(errors)

      gen_errors(all_errors, unquote(module))
    end
  end

  @doc """
    This code takes care of generating each function corresponding to errors listed in the `@errors` array.
    It basically loops through the array and generates two functions for each error:
    - one that returns the error without metadata
    - one that returns the error with metadata.

    Here is an example. Imagine that the `@errors` array contains the following errors:
    ```
      [
        {:unknown_error, "Unknown error"},
      ]
    ```

    The following functions will be generated:
    ```
      def unknown_error() do
        %BusinessError{
          message: "Unknown error",
          reason: :unknown_error
        }
      end

      def unknown_error(metadata) do
        %BusinessError{
          message: "Unknown error",
          reason: :unknown_error,
          data: metadata
        }
      end
    ```
  """
  defmacro gen_errors(errors, module) do
    # See https://hexdocs.pm/elixir/Kernel.SpecialForms.html#quote/2-binding-and-unquote-fragments
    # to explain why we use bind_quoted
    quote bind_quoted: [errors: errors, module: module] do
      alias LenraCommon.Errors.ErrorGenerator

      Enum.each(errors, fn err ->
        reason = elem(err, 0)
        fn_tuple = (Atom.to_string(reason) <> "_tuple") |> String.to_atom()

        err = Macro.escape(err)

        def unquote(reason)(metadata \\ %{}) do
          ErrorGenerator.create_struct(unquote(module), metadata, unquote(err))
        end

        def unquote(fn_tuple)(metadata \\ %{}) do
          result =
            ErrorGenerator.create_struct(
              unquote(module),
              metadata,
              unquote(err)
            )

          {:error, result}
        end
      end)
    end
  end

  def create_struct(mod, metadata, {reason, message}) do
    struct(mod, message: message, reason: reason, metadata: metadata)
  end

  def create_struct(mod, metadata, {reason, message, status}) do
    struct(mod, message: message, reason: reason, metadata: metadata, status_code: status)
  end
end
