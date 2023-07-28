defmodule Lenra.Errors.BusinessError do
  @moduledoc """
    Lenra.Errors.BusinessError handles business errors for the Lenra app.
    This module uses LenraCommon.Errors.BusinessError
  """

  use LenraCommon.Errors.ErrorGenerator,
    module: LenraCommon.Errors.BusinessError,
    inherit: true,
    errors: [
      {:passwords_must_match, "Passwords must match."},
      {:null_parameters, "Parameters can't be null."},
      {:no_validation_code, "There is no validation code for this user."},
      {:incorrect_email_or_password, "Incorrect email or password"},
      {:no_such_registration_code, "No such registration code"},
      {:no_such_password_code, "No such password lost code"},
      {:password_already_used, "Your password cannot be equal to the last 3."},
      {:incorrect_email, "Incorrect email"},
      {:wrong_environment, "Deployment env does not match build env"},
      {:already_dev, "You are already a dev"},
      {:invalid_uuid, "The code is not a valid UUID"},
      {:invalid_code, "The code is invalid"},
      {:invalid_build_status, "The build status should be success or failure."},
      {:invalid_token, "The token is invalid."},
      {:no_app_authorization, "You are not authorized to join this app."},
      {:not_latest_cgu, "Not latest CGU."},
      {:did_not_accept_cgu, "You must accept the CGU to use Lenra"},
      {:no_app_found, "No application found for the current link"},
      {:invitation_wrong_email, "Cannot accept the invitation with this email."},
      {:application_not_built, "Your application has not been built yet."},
      {:pipeline_runner_unkown_service, "Currently not capable to handle this type of pipeline. (`pipeline_runner` can be: [GitLab, Kubernetes])"}
    ]
end
