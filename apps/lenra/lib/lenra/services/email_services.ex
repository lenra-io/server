defmodule Lenra.EmailService do
  @moduledoc false

  import Bamboo.Email
  alias Bamboo.SendGridHelper

  @spec create_welcome_email(String.t(), String.t()) :: Bamboo.Email.t()
  def create_welcome_email(email_address, code) do
    # base template ID : d-bd160809d9a04b07ac6925a823f8f61c
    new_email()
    |> to(email_address)
    |> from({"Len at Lenra", Application.fetch_env!(:lenra, :lenra_email)})
    |> SendGridHelper.with_template("d-311a3dc52f6d44c2b613e3367e7ba82b")
    |> SendGridHelper.add_dynamic_field("token", code)
  end

  @spec create_recovery_email(String.t(), String.t()) :: Bamboo.Email.t()
  def create_recovery_email(email_address, code) do
    # base template ID : d-4f7744c575434313a767f1b11cc389c1
    new_email()
    |> to(email_address)
    |> from({"Len at Lenra", Application.fetch_env!(:lenra, :lenra_email)})
    |> SendGridHelper.with_template("d-4f7744c575434313a767f1b11cc389c1")
    |> SendGridHelper.add_dynamic_field("token", code)
  end

  @spec create_invitation_email(String.t(), String.t(), String.t()) :: Bamboo.Email.t()
  def create_invitation_email(email_address, application_name, app_link) do
    # base template ID : d-61866b0c62b347d3880155d680036f65
    new_email()
    |> to(email_address)
    |> from({"Len at Lenra", Application.fetch_env!(:lenra, :lenra_email)})
    |> SendGridHelper.with_template("d-61866b0c62b347d3880155d680036f65")
    |> SendGridHelper.add_dynamic_field("application_name", application_name)
    |> SendGridHelper.add_dynamic_field("app_link", app_link)
  end
end
