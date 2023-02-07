defmodule Lenra.NotifyWorker do
  @moduledoc """
    Worker to use for send email
  """
  alias Lenra.Notifications
  require Logger

  def add_push_notif(provider, notif) do
    EventQueue.add_event(:push_notif, [provider, notif])
  end

  def push_notif(provider, notif) do
    case provider.system do
      :unified_push ->
        Notifications.send_up_notification(provider, notif)

      _ ->
        raise "Not implemented"
    end
  end
end
