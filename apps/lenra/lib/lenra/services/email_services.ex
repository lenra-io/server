defmodule Lenra.EmailService do
  @moduledoc false

  import Bamboo.Email
  alias Bamboo.SendGridHelper

  def create_welcome_email(email_address, code) do
    # base template ID : d-bd160809d9a04b07ac6925a823f8f61c
    new_email()
    |> to(email_address)
    |> from("no-reply@lenra.io")
    |> subject("Bienvenue!")
    |> SendGridHelper.with_template("d-bd160809d9a04b07ac6925a823f8f61c")
    |> SendGridHelper.add_dynamic_field("title", "Bienvenue Chez Lenra " <> email_address <> "!")
    |> SendGridHelper.add_dynamic_field("message", "Votre code : " <> code)
  end

  def create_recovery_email(email_address, code) do
    new_email()
    |> to(email_address)
    |> from("no-reply@lenra.io")
    |> subject("Votre code de vérification!")
    |> SendGridHelper.with_template("d-bd160809d9a04b07ac6925a823f8f61c")
    |> SendGridHelper.add_dynamic_field("title", "Bonjour " <> email_address)
    |> SendGridHelper.add_dynamic_field("message", "Votre code : " <> code)
  end
end
