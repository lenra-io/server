defmodule LenraWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  alias Lenra.Errors.{BusinessError, TechnicalError}

  @errors [
    unknown_error: %TechnicalError{reason: :unknown_error, message: "Unknown error"},
    passwords_must_match: %BusinessError{
      reason: :passwords_must_match,
      message: "Passwords must match."
    },
    null_parameters: %BusinessError{
      reason: :null_parameters,
      message: "Parameters can't be null."
    },
    no_validation_code: %BusinessError{
      reason: :no_validation_code,
      message: "There is no validation code for this user."
    },
    incorrect_email_or_password: %BusinessError{
      reason: :incorrect_email_or_password,
      message: "Incorrect email or password"
    },
    no_such_registration_code: %BusinessError{
      reason: :no_such_registration_code,
      message: "No such registration code"
    },
    no_such_password_code: %BusinessError{
      reason: :no_such_password_code,
      message: "No such password lost code"
    },
    unhandled_resource_type: %TechnicalError{
      reason: :unhandled_resource_type,
      message: "Unknown resource."
    },
    password_already_used: %BusinessError{
      reason: :password_already_used,
      message: "Your password cannot be equal to the last 3."
    },
    incorrect_email: %BusinessError{reason: :incorrect_email, message: "Incorrect email"},
    wrong_environment: %BusinessError{
      reason: :wrong_environment,
      message: "Deployment env does not match build env"
    },
    dev_code_already_used: %BusinessError{
      reason: :dev_code_already_used,
      message: "The code is already used"
    },
    already_dev: %BusinessError{reason: :already_dev, message: "You are already a dev"},
    invalid_uuid: %BusinessError{reason: :invalid_uuid, message: "The code is not a valid UUID"},
    invalid_code: %BusinessError{reason: :invalid_code, message: "The code is invalid"},
    invalid_build_status: %BusinessError{
      reason: :invalid_build_status,
      message: "The build status should be success or failure."
    },
    openfaas_not_reachable: %TechnicalError{
      reason: :openfaas_not_reachable,
      message: "Openfaas could not be reached."
    },
    application_not_found: %TechnicalError{
      reason: :application_not_found,
      message: "The application was not found in Openfaas."
    },
    listener_not_found: %TechnicalError{
      reason: :listener_not_found,
      message: "No listener found in app manifest."
    },
    openfaas_delete_error: %TechnicalError{
      reason: :openfaas_delete_error,
      message: "Openfaas could not delete the application."
    },
    timeout: %TechnicalError{reason: :timeout, message: "Openfaas timeout."},
    no_app_found: %TechnicalError{
      reason: :no_app_found,
      message: "No application found for the current link."
    },
    environment_not_built: %TechnicalError{
      reason: :environment_not_built,
      message: "This application was not yet build."
    },
    widget_not_found: %TechnicalError{
      reason: :widget_not_found,
      message: "No Widget found in app manifest."
    },
    no_app_authorization: %BusinessError{
      reason: :no_app_authorization,
      message: "You are not authorized to join this app."
    },
    invalid_ui: %TechnicalError{reason: :invalid_ui, message: "Invalid UI"},
    not_latest_cgu: %BusinessError{reason: :not_latest_cgu, message: "Not latest CGU."},
    datastore_not_found: %TechnicalError{
      reason: :datastore_not_found,
      message: "Datastore cannot be found"
    },
    data_not_found: %TechnicalError{reason: :data_not_found, message: "Data cannot be found"},
    bad_request: %TechnicalError{
      reason: :bad_request,
      message: "Server cannot understand or process the request due to a client-side error."
    },
    error_404: %TechnicalError{reason: :error_404, message: "Not Found."},
    error_500: %TechnicalError{reason: :error_500, message: "Internal server error."},
    forbidden: %BusinessError{reason: :forbidden, message: "Forbidden"},
    did_not_accept_cgu: %BusinessError{
      reason: :did_not_accept_cgu,
      message: "You must accept the CGU to use Lenra"
    }
  ]

  def translate_error(%Ecto.Changeset{errors: errors}) do
    Enum.map(errors, &translate_ecto_error/1)
  end

  def translate_error(err) when is_atom(err) do
    Keyword.get(@errors, err, %{error: "Unknown error"}).message
  end

  def translate_ecto_error({field, {msg, opts}}) do
    message =
      Enum.reduce(opts, "#{field} #{msg}", fn
        {_key, {:parameterized, _, _}}, acc -> acc
        {key, value}, acc -> String.replace(acc, "%{#{key}}", to_string(value))
      end)

    %{error: message}
  end
end
