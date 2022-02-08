defmodule Lenra.EmailService do
  @moduledoc false

  import Bamboo.Email
  alias Bamboo.SendGridHelper

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
end
