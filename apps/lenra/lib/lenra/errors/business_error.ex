defmodule Lenra.Errors.BusinessError do
  @type t() :: %__MODULE__{
          message: String.t(),
          reason: atom(),
          data: any()
        }

  @enforce_keys [:message, :reason]
  defexception [:message, :reason, :data]

  alias Lenra.Errors.BusinessError

  def passwords_must_match do
    %BusinessError{
      reason: :passwords_must_match,
      message: "Passwords must match."
    }
  end

  def null_parameters do
    %BusinessError{
      reason: :null_parameters,
      message: "Parameters can't be null."
    }
  end

  def no_validation_code do
    %BusinessError{
      reason: :no_validation_code,
      message: "There is no validation code for this user."
    }
  end

  def incorrect_email_or_password do
    %BusinessError{
      reason: :incorrect_email_or_password,
      message: "Incorrect email or password"
    }
  end

  def no_such_registration_code do
    %BusinessError{
      reason: :no_such_registration_code,
      message: "No such registration code"
    }
  end

  def no_such_password_code do
    %BusinessError{
      reason: :no_such_password_code,
      message: "No such password lost code"
    }
  end

  def password_already_used do
    %BusinessError{
      reason: :password_already_used,
      message: "Your password cannot be equal to the last 3."
    }
  end

  def incorrect_email do
    %BusinessError{reason: :incorrect_email, message: "Incorrect email"}
  end

  def wrong_environment do
    %BusinessError{
      reason: :wrong_environment,
      message: "Deployment env does not match build env"
    }
  end

  def dev_code_already_used do
    %BusinessError{
      reason: :dev_code_already_used,
      message: "The code is already used"
    }
  end

  def already_dev do
    %BusinessError{reason: :already_dev, message: "You are already a dev"}
  end

  def invalid_uuid do
    %BusinessError{reason: :invalid_uuid, message: "The code is not a valid UUID"}
  end

  def invalid_code do
    %BusinessError{reason: :invalid_code, message: "The code is invalid"}
  end

  def invalid_build_status do
    %BusinessError{
      reason: :invalid_build_status,
      message: "The build status should be success or failure."
    }
  end

  def no_app_authorization do
    %BusinessError{
      reason: :no_app_authorization,
      message: "You are not authorized to join this app."
    }
  end

  def not_latest_cgu do
    %BusinessError{reason: :not_latest_cgu, message: "Not latest CGU."}
  end

  def forbidden do
    %BusinessError{reason: :forbidden, message: "Forbidden"}
  end

  def did_not_accept_cgu do
    %BusinessError{
      reason: :did_not_accept_cgu,
      message: "You must accept the CGU to use Lenra"
    }
  end
end
