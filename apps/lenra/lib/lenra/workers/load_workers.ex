defmodule Lenra.LoadWorker do
  @moduledoc """
    function to load worker in eventQueue
  """
  alias Lenra.{EmailWorker, NotifyWorker}

  def load do
    EventQueue.add_worker(EmailWorker, :email_verification)
    EventQueue.add_worker(EmailWorker, :email_password_lost)
    EventQueue.add_worker(EmailWorker, :email_invitation)
    EventQueue.add_worker(NotifyWorker, :unified_push)
  end
end
