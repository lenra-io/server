defmodule Lenra.NotifyWorker do
  @moduledoc """
    Worker to use for send email
  """
  alias Lenra.Notifications
  require Logger

  def add_unified_push_notif(provider, notif) do
    EventQueue.add_event(:unified_push, [provider, notif])
  end

  def unified_push(provider, notif) do
    Notifications.send_up_notification(provider, notif)
  end
end
