defmodule Lenra.Errors.BusinessError do
  @moduledoc """
    Lenra.Errors.BusinessError handle technical error for the Lenra app.
    This module used LenraCommon.Errors.BusinessError
  """
  alias LenraCommon.Errors.BusinessError

  @errors [
    {:passwords_must_match, "Passwords must match."},
    {:null_parameters, "Parameters can't be null."},
    {:no_validation_code, "There is no validation code for this user."},
    {:incorrect_email_or_password, "Incorrect email or password"},
    {:no_such_registration_code, "No such registration code"},
    {:no_such_password_code, "No such password lost code"},
    {:password_already_used, "Your password cannot be equal to the last 3."},
    {:incorrect_email, "Incorrect email"},
    {:wrong_environment, "Deployment env does not match build env"},
    {:dev_code_already_used, "The code is already used"},
    {:already_dev, "You are already a dev"},
    {:invalid_uuid, "The code is not a valid UUID"},
    {:invalid_code, "The code is invalid"},
    {:invalid_build_status, "The build status should be success or failure."},
    {:no_app_authorization, "You are not authorized to join this app."},
    {:not_latest_cgu, "Not latest CGU."},
    {:did_not_accept_cgu, "You must accept the CGU to use Lenra"}
  ]

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
  Enum.each(@errors, fn {reason, message} ->
    fn_tuple = (Atom.to_string(reason) <> "_tuple") |> String.to_atom()

    def unquote(reason)(metadata \\ %{}) do
      %BusinessError{
        message: unquote(message),
        reason: unquote(reason),
        metadata: metadata
      }
    end

    def unquote(fn_tuple)(metadata \\ %{}) do
      {:error,
       %BusinessError{
         message: unquote(message),
         reason: unquote(reason),
         metadata: metadata
       }}
    end
  end)
end