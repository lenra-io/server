defmodule Lenra.EmailWorker do
  @moduledoc """
    Worker to use for send email
  """
  require Logger

  alias Lenra.{User, EmailService, Mailer}

  def add_email_verification_event(user, code) do
    EventQueue.add_event(:email_verification, [user, code])
  end

  def add_email_password_lost_event(user, code) do
    EventQueue.add_event(:email_password_lost, [user, code])
  end

  def email_verification(
        %User{} = user,
        code
      ) do
    EmailService.create_welcome_email(user.email, code, user.first_name)
    |> Mailer.deliver_now()
  end

  def email_password_lost(
        %User{} = user,
        code
      ) do
    EmailService.create_recovery_email(user.email, code, user.first_name)
    |> Mailer.deliver_now()
  end
end
