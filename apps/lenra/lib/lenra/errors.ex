defmodule Lenra.Errors do
  @moduledoc """
    Lenra.Errors defines three error types to cover all of the possible errors accross the Lenra server.
  """

  alias Lenra.Errors.{BusinessError, TechnicalError}

  # defdelegate passwords_must_match, to: BusinessError, as: :passwords_must_match
  # defdelegate null_parameters, to: BusinessError, as: :null_parameters
  # defdelegate no_validation_code, to: BusinessError, as: :no_validation_code
  # defdelegate incorrect_email_or_password, to: BusinessError, as: :incorrect_email_or_password
  # defdelegate no_such_registration_code, to: BusinessError, as: :no_such_registration_code
  # defdelegate no_such_password_code, to: BusinessError, as: :no_such_password_code
  # defdelegate password_already_used, to: BusinessError, as: :password_already_used
  # defdelegate incorrect_email, to: BusinessError, as: :incorrect_email
  # defdelegate wrong_environment, to: BusinessError, as: :wrong_environment
  # defdelegate dev_code_already_used, to: BusinessError, as: :dev_code_already_used
  # defdelegate already_dev, to: BusinessError, as: :already_dev
  # defdelegate invalid_uuid, to: BusinessError, as: :invalid_uuid
  # defdelegate invalid_code, to: BusinessError, as: :invalid_code
  # defdelegate invalid_build_status, to: BusinessError, as: :invalid_build_status
  # defdelegate no_app_authorization, to: BusinessError, as: :no_app_authorization
  # defdelegate not_latest_cgu, to: BusinessError, as: :not_latest_cgu
  # defdelegate forbidden, to: LenraCommon.Errors.BusinessError, as: :forbidden
  # defdelegate did_not_accept_cgu, to: BusinessError, as: :did_not_accept_cgu

  # defdelegate unknown_error, to: LenraCommon.Errors.TechnicalError, as: :unknown_error
  # defdelegate openfaas_not_reachable, to: TechnicalError, as: :openfaas_not_reachable
  # defdelegate unhandled_resource_type, to: TechnicalError, as: :unhandled_resource_type
  # defdelegate application_not_found, to: TechnicalError, as: :application_not_found
  # defdelegate listener_not_found, to: TechnicalError, as: :listener_not_found
  # defdelegate openfaas_delete_error, to: TechnicalError, as: :openfaas_delete_error
  # defdelegate timeout, to: TechnicalError, as: :timeout
  # defdelegate no_app_found, to: TechnicalError, as: :no_app_found
  # defdelegate environment_not_built, to: TechnicalError, as: :environment_not_built
  # defdelegate widget_not_found, to: TechnicalError, as: :widget_not_found
  # defdelegate invalid_ui, to: TechnicalError, as: :invalid_ui
  # defdelegate datastore_not_found, to: TechnicalError, as: :datastore_not_found
  # defdelegate data_not_found, to: TechnicalError, as: :data_not_found
  # defdelegate bad_request, to: LenraCommon.Errors.TechnicalError, as: :bad_request
  # defdelegate error_404, to: LenraCommon.Errors.TechnicalError, as: :error_404
  # defdelegate error_500, to: LenraCommon.Errors.TechnicalError, as: :error_500
end
