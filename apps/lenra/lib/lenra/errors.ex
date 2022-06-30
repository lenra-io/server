defmodule Lenra.Errors.BusinessError do
  @type t() :: %__MODULE__{
          message: String.t(),
          reason: atom(),
          data: any()
        }

  @enforce_keys [:message, :reason]
  defexception [:message, :reason, :data]
end

defmodule Lenra.Errors.TechnicalError do
  @type t() :: %__MODULE__{
          message: String.t(),
          reason: atom(),
          data: any()
        }

  @enforce_keys [:message, :reason]
  defexception [:message, :reason, :data]
end

defmodule Lenra.Errors.DevError do
  @type t() :: %__MODULE__{
          message: String.t(),
          reason: atom(),
          data: any()
        }

  @enforce_keys [:message, :reason]
  defexception [:message, :reason, :data]

  def message(%{message: message}) when is_bitstring(message) do
    message
  end

  def message(_e) do
    "An unknown error occured."
  end
end

defmodule Lenra.Errors do
  alias Lenra.Errors.{BusinessError, TechnicalError}

  def unknown_error() do
    %TechnicalError{reason: :unknown_error, message: "Unknown error"}
  end

  def passwords_must_match() do
    %BusinessError{
      reason: :passwords_must_match,
      message: "Passwords must match."
    }
  end

  def null_parameters() do
    %BusinessError{
      reason: :null_parameters,
      message: "Parameters can't be null."
    }
  end

  def no_validation_code() do
    %BusinessError{
      reason: :no_validation_code,
      message: "There is no validation code for this user."
    }
  end

  def incorrect_email_or_password() do
    %BusinessError{
      reason: :incorrect_email_or_password,
      message: "Incorrect email or password"
    }
  end

  def no_such_registration_code() do
    %BusinessError{
      reason: :no_such_registration_code,
      message: "No such registration code"
    }
  end

  def no_such_password_code() do
    %BusinessError{
      reason: :no_such_password_code,
      message: "No such password lost code"
    }
  end

  def unhandled_resource_type() do
    %TechnicalError{
      reason: :unhandled_resource_type,
      message: "Unknown resource."
    }
  end

  def password_already_used() do
    %BusinessError{
      reason: :password_already_used,
      message: "Your password cannot be equal to the last 3."
    }
  end

  def incorrect_email() do
    %BusinessError{reason: :incorrect_email, message: "Incorrect email"}
  end

  def wrong_environment() do
    %BusinessError{
      reason: :wrong_environment,
      message: "Deployment env does not match build env"
    }
  end

  def dev_code_already_used() do
    %BusinessError{
      reason: :dev_code_already_used,
      message: "The code is already used"
    }
  end

  def already_dev() do
    %BusinessError{reason: :already_dev, message: "You are already a dev"}
  end

  def invalid_uuid() do
    %BusinessError{reason: :invalid_uuid, message: "The code is not a valid UUID"}
  end

  def invalid_code() do
    %BusinessError{reason: :invalid_code, message: "The code is invalid"}
  end

  def invalid_build_status() do
    %BusinessError{
      reason: :invalid_build_status,
      message: "The build status should be success or failure."
    }
  end

  def openfaas_not_reachable() do
    %TechnicalError{
      reason: :openfaas_not_reachable,
      message: "Openfaas could not be reached."
    }
  end

  def application_not_found() do
    %TechnicalError{
      reason: :application_not_found,
      message: "The application was not found in Openfaas."
    }
  end

  def listener_not_found() do
    %TechnicalError{
      reason: :listener_not_found,
      message: "No listener found in app manifest."
    }
  end

  def openfaas_delete_error() do
    %TechnicalError{
      reason: :openfaas_delete_error,
      message: "Openfaas could not delete the application."
    }
  end

  def timeout() do
    %TechnicalError{reason: :timeout, message: "Openfaas timeout."}
  end

  def no_app_found() do
    %TechnicalError{
      reason: :no_app_found,
      message: "No application found for the current link."
    }
  end

  def environment_not_built() do
    %TechnicalError{
      reason: :environment_not_built,
      message: "This application was not yet build."
    }
  end

  def widget_not_found() do
    %TechnicalError{
      reason: :widget_not_found,
      message: "No Widget found in app manifest."
    }
  end

  def no_app_authorization() do
    %BusinessError{
      reason: :no_app_authorization,
      message: "You are not authorized to join this app."
    }
  end

  def invalid_ui() do
    %TechnicalError{reason: :invalid_ui, message: "Invalid UI"}
  end

  def not_latest_cgu() do
    %BusinessError{reason: :not_latest_cgu, message: "Not latest CGU."}
  end

  def datastore_not_found() do
    %TechnicalError{
      reason: :datastore_not_found,
      message: "Datastore cannot be found"
    }
  end

  def data_not_found() do
    %TechnicalError{reason: :data_not_found, message: "Data cannot be found"}
  end

  def bad_request() do
    %TechnicalError{
      reason: :bad_request,
      message: "Server cannot understand or process the request due to a client-side error."
    }
  end

  def error_404() do
    %TechnicalError{reason: :error_404, message: "Not Found."}
  end

  def error_500() do
    %TechnicalError{reason: :error_500, message: "Internal server error."}
  end

  def forbidden() do
    %BusinessError{reason: :forbidden, message: "Forbidden"}
  end

  def did_not_accept_cgu() do
    %BusinessError{
      reason: :did_not_accept_cgu,
      message: "You must accept the CGU to use Lenra"
    }
  end
end

# defmodule Test do
#   def business_error do
#     {:error, Lenra.Errors.BusinessError.exception(message: "This account does not exists.", reason: :invalid_account)}
#   end

#   def tech_error do
#     {:error,
#      Lenra.Errors.TechnicalError.exception(
#        message: "Openfaas not reachable. Please retry later !",
#        reason: :openfaas_not_reachable
#      )}
#   end

#   def exception do
#     raise Lenra.Errors.DevError, "Snap, we should not go into this !"
#   end
# end
