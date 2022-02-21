defmodule LenraWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  @errors [
    unknow_error: %{code: 0, message: "Unknown error"},
    password_not_equals: %{code: 1, message: "Password must be equals."},
    parameters_null: %{code: 2, message: "Parameters can't be null."},
    no_validation_code: %{
      code: 3,
      message: "There is no validation code for this user."
    },
    email_or_password_incorrect: %{code: 4, message: "Incorrect email or password"},
    no_such_registration_code: %{code: 5, message: "No such registration code"},
    no_such_password_code: %{code: 6, message: "No such password lost code"},
    unhandled_resource_type: %{code: 7, message: "Unknown resource."},
    password_already_used: %{code: 8, message: "Your password cannot be equal to the last 3."},
    email_incorrect: %{code: 9, message: "Incorrect email"},
    wrong_environment: %{code: 10, message: "Deployment env not equals to build env"},
    dev_code_already_used: %{code: 11, message: "The code is already used"},
    already_dev: %{code: 12, message: "You are already a dev"},
    invalid_uuid: %{code: 13, message: "The code is not a valid UUID"},
    invalid_code: %{code: 14, message: "The code is invalid"},
    invalid_build_status: %{code: 15, message: "The build status should be success or failure."},
    openfass_not_recheable: %{code: 16, message: "Openfaas could not be reached. This should not happen."},
    application_not_found: %{code: 17, message: "The application was not found in Openfaas. This should not happen."},
    listener_not_found: %{code: 18, message: "No listener found in app manifest. This should not happen."},
    openfaas_delete_error: %{code: 19, message: "Openfaas could not delete the application. This should not happen."},
    timeout: %{code: 20, message: "Openfaas timeout. This should not happen."},
    no_app_found: %{code: 21, message: "No application found for the current link."},
    widget_not_found: %{code: 23, message: "No Widget found in app manifest. This should not happen."},
    error_404: %{code: 404, message: "Not Found."},
    error_500: %{code: 500, message: "Internal server error."},
    openfaas_not_reachable: %{code: 1000, message: "Openfaas is not accessible"},
    forbidden: %{code: 403, message: "Forbidden"}
  ]

  def translate_errors([]), do: []
  def translate_errors([err | errs]), do: translate_error(err) ++ translate_errors(errs)

  def translate_error(%Ecto.Changeset{errors: errors}) do
    Enum.map(errors, &translate_ecto_error/1)
  end

  def translate_error(err) when is_atom(err) do
    [Keyword.get(@errors, err, %{code: 0, message: "Unknown error"})]
  end

  def translate_ecto_error({field, {msg, opts}}) do
    message =
      Enum.reduce(opts, "#{field} #{msg}", fn
        {_key, {:parameterized, _, _}}, acc -> acc
        {key, value}, acc -> String.replace(acc, "%{#{key}}", to_string(value))
      end)

    %{code: 0, message: message}
  end
end
