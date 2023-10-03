defmodule Lenra.Errors.TechnicalError do
  @moduledoc """
    Lenra.Errors.TechnicalError handles technical errors for the Lenra app.
    This module uses LenraCommon.Errors.TechnicalError
  """

  use LenraCommon.Errors.ErrorGenerator,
    module: LenraCommon.Errors.TechnicalError,
    inherit: true,
    errors: [
      {:openfaas_not_reachable, "Openfaas could not be reached."},
      {:unhandled_resource_type, "Unknown resource."},
      {:application_not_found, "The application was not found in Openfaas."},
      {:openfaas_delete_error, "Openfaas could not delete the application."},
      {:timeout, "Openfaas timeout."},
      {:no_app_found, "No application found for the current link."},
      {:environment_not_built, "This application was not yet build."},
      {:invalid_ui, "Invalid UI"},
      {:datastore_not_found, "Datastore cannot be found"},
      {:data_not_found, "Data cannot be found"},
      {:cgs_not_found, "CGS cannot be found"},
      {:file_not_found, "File not found"},
      {:cannot_save_oauth2_client, "The Oauth client cannot be saved."},
      {:hydra_request_failed, "The request to hydra failed."}
    ]
end
