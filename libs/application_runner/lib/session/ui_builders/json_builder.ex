defmodule ApplicationRunner.Session.UiBuilders.JsonBuilder do
  @moduledoc """
    This module is responsible of building the JSON view.
  """
  @behaviour ApplicationRunner.Session.UiBuilders.UiBuilderAdapter

  alias ApplicationRunner.Environment
  alias ApplicationRunner.Session.RouteServer
  alias ApplicationRunner.Session.UiBuilders.ViewBuilderHelper

  require Logger

  @type view :: map()
  @type component :: map()

  @impl ApplicationRunner.Session.UiBuilders.UiBuilderAdapter
  def get_routes(env_id, roles) do
    Environment.ManifestHandler.get_routes(env_id, "json", roles)
  end

  @impl ApplicationRunner.Session.UiBuilders.UiBuilderAdapter
  def build_ui(session_metadata, view_uid) do
    ViewBuilderHelper.build_ui(__MODULE__, session_metadata, view_uid)
  end

  # Build the view result components.
  @impl ApplicationRunner.Session.UiBuilders.UiBuilderAdapter
  def build_components(
        session_metadata,
        %{"_type" => comp_type} = component,
        ui_context,
        view_uid
      ) do
    Logger.debug("#{__MODULE__} build_components with component: #{inspect(component)}")

    # TODO: validate component ?
    case comp_type do
      "view" ->
        ViewBuilderHelper.handle_view(__MODULE__, session_metadata, component, ui_context, view_uid)

      "listener" ->
        ViewBuilderHelper.handle_listener(__MODULE__, session_metadata, component, ui_context, view_uid)

      _ ->
        Logger.warn("Unknown component type for JSON view: #{comp_type}")
        {:ok, component, ui_context}
    end
  end

  def build_components(
        session_metadata,
        component,
        ui_context,
        view_uid
      )
      when is_map(component) do
    {new_context, new_component} =
      Enum.reduce(
        component,
        {ui_context, %{}},
        fn {k, v}, {context, acc} ->
          case build_components(session_metadata, v, context, view_uid) do
            {:ok, new_sub_component, new_ui_context} ->
              {new_ui_context, Map.put(acc, k, new_sub_component)}

            _ ->
              {context, Map.put(acc, k, v)}
          end
        end
      )

    {:ok, new_component, new_context}
  end

  def build_components(
        session_metadata,
        component,
        ui_context,
        view_uid
      )
      when is_list(component) do

    {new_context, new_component} =
      Enum.reduce(
        component,
        {ui_context, []},
        fn v, {context, acc} ->
          case build_components(session_metadata, v, context, view_uid) do
            {:ok, new_sub_component, new_ui_context} ->
              {new_ui_context, [new_sub_component | acc]}

            _ ->
              {context, [v | acc]}
          end
        end
      )

    {:ok, Enum.reverse(new_component), new_context}
  end

  def build_components(
        _session_metadata,
        component,
        ui_context,
        _view_uid
      ) do
    {:ok, component, ui_context}
  end
end
