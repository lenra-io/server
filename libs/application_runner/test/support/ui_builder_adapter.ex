defmodule ApplicationRunner.FakeUiBuilderAdapter do
  @moduledoc """
  This adapter emulate a builder adapter.
  """
  alias ApplicationRunner.Errors.TechnicalError
  @behaviour ApplicationRunner.Session.UiBuilders.UiBuilderAdapter

  @impl true
  def get_routes(_env_id, _roles) do
    []
  end

  @impl true
  def build_ui(_session_metadata, _view_uid) do
    {:ok, %{}}
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
