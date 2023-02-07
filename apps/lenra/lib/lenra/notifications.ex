defmodule Lenra.Notifications do
  alias Lenra.NotifyWorker
  alias Lenra.Repo
  alias Lenra.Notifications.{NotifyProvider}
  alias ApplicationRunner.Notifications.Notif
  import Ecto.Query, only: [from: 2]

  def set_notify_provider(params) do
    params
    |> NotifyProvider.new()
    |> Repo.insert(
      on_conflict: :replace_all,
      conflict_target: [:device_id]
    )
  end

  defp get_providers(user_ids) do
    from(np in NotifyProvider, where: np.user_id in ^user_ids)
    |> Repo.all()
  end

  def notify(%Notif{} = notif) do
    get_providers(notif.to_uids)
    |> Enum.map(fn %NotifyProvider{} = provider ->
      NotifyWorker.add_push_notif(provider, notif)
    end)
  end

  def send_up_notification(%NotifyProvider{} = provider, %Notif{} = notif) do
    string_params_body = construct_string_body(notif)

    Finch.build(:post, provider.endpoint, [], string_params_body)
    |> Finch.request(UnifiedPushHttp)
  end

  defp construct_string_body(%Notif{} = body) do
    [:message, :title, :tags, :priority, :attach, :actions, :click, :at]
    |> Enum.reduce("", fn elem, url_params ->
      case Map.get(body, elem) do
        nil ->
          url_params

        res ->
          key = Atom.to_string(elem)
          "#{url_params}&#{key}=#{res}"
      end
    end)
  end
end
