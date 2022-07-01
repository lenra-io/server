defmodule Lenra.Errors.TechnicalError do
  alias Lenra.Errors.TechnicalError

  @type t() :: %__MODULE__{
          message: String.t(),
          reason: atom(),
          data: any()
        }

  @enforce_keys [:message, :reason]
  defexception [:message, :reason, :data]

  def unknown_error do
    %TechnicalError{reason: :unknown_error, message: "Unknown error"}
  end

  def openfaas_not_reachable do
    %TechnicalError{
      reason: :openfaas_not_reachable,
      message: "Openfaas could not be reached."
    }
  end

  def unhandled_resource_type do
    %TechnicalError{
      reason: :unhandled_resource_type,
      message: "Unknown resource."
    }
  end

  def application_not_found do
    %TechnicalError{
      reason: :application_not_found,
      message: "The application was not found in Openfaas."
    }
  end

  def listener_not_found do
    %TechnicalError{
      reason: :listener_not_found,
      message: "No listener found in app manifest."
    }
  end

  def openfaas_delete_error do
    %TechnicalError{
      reason: :openfaas_delete_error,
      message: "Openfaas could not delete the application."
    }
  end

  def timeout do
    %TechnicalError{reason: :timeout, message: "Openfaas timeout."}
  end

  def no_app_found do
    %TechnicalError{
      reason: :no_app_found,
      message: "No application found for the current link."
    }
  end

  def environment_not_built do
    %TechnicalError{
      reason: :environment_not_built,
      message: "This application was not yet build."
    }
  end

  def widget_not_found do
    %TechnicalError{
      reason: :widget_not_found,
      message: "No Widget found in app manifest."
    }
  end

  def invalid_ui do
    %TechnicalError{reason: :invalid_ui, message: "Invalid UI"}
  end

  def datastore_not_found do
    %TechnicalError{
      reason: :datastore_not_found,
      message: "Datastore cannot be found"
    }
  end

  def data_not_found do
    %TechnicalError{reason: :data_not_found, message: "Data cannot be found"}
  end

  def bad_request do
    %TechnicalError{
      reason: :bad_request,
      message: "Server cannot understand or process the request due to a client-side error."
    }
  end

  def error_404 do
    %TechnicalError{reason: :error_404, message: "Not Found."}
  end

  def error_500 do
    %TechnicalError{reason: :error_500, message: "Internal server error."}
  end
end
