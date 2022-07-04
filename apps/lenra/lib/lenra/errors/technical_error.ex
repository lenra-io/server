defmodule Lenra.Errors.TechnicalError do
  alias Lenra.Errors.TechnicalError

  @type t() :: %__MODULE__{
          message: String.t(),
          reason: atom(),
          data: any()
        }

  @enforce_keys [:message, :reason]
  defexception [:message, :reason, :data]

  @errors [
    {:unknown_error, "Unknown error"},
    {:openfaas_not_reachable, "Openfaas could not be reached."},
    {:unhandled_resource_type, "Unknown resource."},
    {:application_not_found, "The application was not found in Openfaas."},
    {:listener_not_found, "No listener found in app manifest."},
    {:openfaas_delete_error, "Openfaas could not delete the application."},
    {:timeout, "Openfaas timeout."},
    {:no_app_found, "No application found for the current link."},
    {:environment_not_built, "This application was not yet build."},
    {:widget_not_found, "No Widget found in app manifest."},
    {:invalid_ui, "Invalid UI"},
    {:datastore_not_found, "Datastore cannot be found"},
    {:data_not_found, "Data cannot be found"},
    {:bad_request, "Server cannot understand or process the request due to a client-side error."},
    {:error_404, "Not Found."},
    {:error_500, "Internal server error."}
  ]

  @doc """
    See Lenra.Errors.BusinessError for more information.
  """
  Enum.each(@errors, fn {reason, message} ->
    def unquote(reason)() do
      %TechnicalError{
        message: unquote(message),
        reason: unquote(reason)
      }
    end

    def unquote(reason)(metadata) do
      %TechnicalError{
        message: unquote(message),
        reason: unquote(reason),
        data: metadata
      }
    end
  end)
end
