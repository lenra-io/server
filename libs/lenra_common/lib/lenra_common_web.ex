defmodule LenraCommonWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use LenraCommonWeb, :controller
      use LenraCommonWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: LenraCommonWeb

      import LenraCommonWeb.ControllerHelpers
      import Plug.Conn

      plug(:put_view, LenraCommonWeb.BaseView)

      action_fallback(LenraCommonWeb.FallbackController)
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/lenra_common_web/templates",
        namespace: LenraCommonWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def view_helpers do
    quote do
      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import LenraCommonWeb.ErrorHelpers
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
