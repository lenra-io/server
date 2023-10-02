defmodule ApplicationRunner.Errors.BusinessError do
  @moduledoc """
    Lenra.Errors.BusinessError handles business errors for the Lenra app.
    This module uses LenraCommon.Errors.BusinessError
  """

  use LenraCommon.Errors.ErrorGenerator,
    module: LenraCommon.Errors.BusinessError,
    inherit: true,
    errors: [
      {:env_not_started, "Environment not stated."},
      {:invalid_token, "Your token is invalid."},
      {:did_not_accept_cgs, "You must accept the CGS to use Lenra"},
      {:unknow_listener_code, "No listeners found for the given code"},
      {:session_not_started, "Session not started"},
      {:json_format_invalid, "JSON format invalid"},
      {:no_app_found, "No application found for the current link"},
      {:not_an_object_id, "The given id is not a valid object id"},
      {:incorrect_view_mode, "The view mode should be one of 'lenra', 'json'."},
      {:no_name_in_listener, "Your listener does not have the required property 'name'"},
      {:route_does_not_exist, "The given route does not exist. Please check your manifest."},
      {:invalid_channel_name, "The given channel name does not exist."},
      {:invalid_params, "Invalid params"},
      {:components_malformated,
       "The components was malformated, check metadata for more details"},
      {:error_during_transaction_start, "An error occured during transaction start."},
      {:mongo_not_started, "Mongo is not started for the given env_id"},
      {:could_not_register_appchannel, "Could not register the AppChannel into swarm"},
      {:null_parameters, "Cannot handle null parameters"},
      {:cannot_start_session, "Cannot start session supervisor"}
    ]
end
