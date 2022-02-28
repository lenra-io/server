defmodule Lenra.EmailWorker do
  @moduledoc """
    Worker to use for send email
  """
  alias Lenra.{EmailService, Mailer, User}
  require Logger

  def add_email_verification_event(user, code) do
    EventQueue.add_event(:email_verification, [user, code])
  end

  def add_email_password_lost_event(user, code) do
    EventQueue.add_event(:email_password_lost, [user, code])
  end

  def add_email_invitation_event(user, application_name, app_link) do
    EventQueue.add_event(:email_invitation, [user, application_name, app_link])
  end

  def email_verification(
        %User{} = user,
        code
      ) do
    user.email
    |> EmailService.create_welcome_email(code)
    |> Mailer.deliver_now()
  end

  def email_password_lost(
        %User{} = user,
        code
      ) do
    user.email
    |> EmailService.create_recovery_email(code)
    |> Mailer.deliver_now()
  end

  def email_invitation(
        %User{} = user,
        application_name,
        app_link
      ) do
    user.email
    |> EmailService.create_invitation_email(application_name, app_link)
    |> Mailer.deliver_now()
  end
end
