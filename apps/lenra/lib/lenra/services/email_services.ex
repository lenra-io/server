defmodule Lenra.EmailService do
  @moduledoc false

  import Bamboo.Email
  alias Bamboo.SendGridHelper

  @spec create_welcome_email(String.t(), String.t()) :: Bamboo.Email.t()
  def create_welcome_email(email_address, code) do
    # base template ID : d-bd160809d9a04b07ac6925a823f8f61c
    new_email()
    |> to(email_address)
    |> from("no-reply@lenra.io")
    |> SendGridHelper.with_template("d-bd160809d9a04b07ac6925a823f8f61c")
    |> SendGridHelper.add_dynamic_field("subject", "Bienvenue !")
    |> SendGridHelper.add_dynamic_field(
      "body_hello",
      "Bonjour " <> email_address <> ",<br />Merci pour votre inscription! Vous rejoignez une communauté incroyable"
    )
    |> SendGridHelper.add_dynamic_field("code", code)
    |> SendGridHelper.add_dynamic_field(
      "body_help",
      "Ce code vous permet de valider votre inscription.<br />Si vous rencontrez un problème contactez-nous à l'adresse mail suivante : <a href=\"mailto:contact@lenra.io?subject=&amp;body=\">contact@lenra.io</a>"
    )
  end

  @spec create_recovery_email(String.t(), String.t()) :: Bamboo.Email.t()
  def create_recovery_email(email_address, code) do
    new_email()
    |> to(email_address)
    |> from("no-reply@lenra.io")
    |> SendGridHelper.with_template("d-bd160809d9a04b07ac6925a823f8f61c")
    |> SendGridHelper.add_dynamic_field("subject", "Votre code de vérification")
    |> SendGridHelper.add_dynamic_field(
      "body_hello",
      "Bonjour " <> email_address <> ",<br />Modifiez votre mot de passe à l'aide du code suivant"
    )
    |> SendGridHelper.add_dynamic_field("code", code)
    |> SendGridHelper.add_dynamic_field(
      "body_help",
      "Ce code vous permet de modifier votre mot de passe.<br />Si vous rencontrez un problème contactez-nous à l'adresse mail suivante : <a href=\"mailto:contact@lenra.io?subject=&amp;body=\">contact@lenra.io</a>"
    )
  end

  @spec create_invitation_email(String.t(), String.t(), String.t()) :: Bamboo.Email.t()
  def create_invitation_email(email_address, application_name, app_link) do
    new_email()
    |> to(email_address)
    |> from("no-reply@lenra.io")
    |> SendGridHelper.with_template("d-bd160809d9a04b07ac6925a823f8f61c")
    |> SendGridHelper.add_dynamic_field("subject", "Invitation à rejoindre une application sur Lenra")
    |> SendGridHelper.add_dynamic_field(
      "body_hello",
      "Bonjour,<br />Vous avez été invité à rejoindre " <>
        application_name <>
        " sur Lenra.<br />Pour y accéder, cliquez sur le lien suivant:"
    )
    |> SendGridHelper.add_dynamic_field("link", app_link)
    |> SendGridHelper.add_dynamic_field(
      "body_help",
      "Si vous rencontrez un problème contactez-nous à l'adresse mail suivante : <a href=\"mailto:contact@lenra.io?subject=&amp;body=\">contact@lenra.io</a>"
    )
    |> SendGridHelper.add_dynamic_field("goodbye", "A bientôt !<br />L'équipe Lenra")
  end
end
