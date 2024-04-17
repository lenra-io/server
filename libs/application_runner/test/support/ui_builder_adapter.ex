defmodule ApplicationRunner.FakeUiBuilderAdapter do
  @behaviour ApplicationRunner.Session.UiBuilders.UiBuilderAdapter

  @impl true
  def get_routes(env_id, roles) do
    :error
  end

  @impl true
  def build_ui(session_metadata, view_uid) do
    :error
  end

  @impl true
  def build_components(
        _session_metadata,
        component,
        ui_context,
        _view_uid
      ) do
    {:ok, component, ui_context}
  end
end
