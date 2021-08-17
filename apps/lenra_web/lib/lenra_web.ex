defmodule LenraWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use LenraWeb, :controller
      use LenraWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: LenraWeb

      import LenraWeb.ControllerHelpers
      import Plug.Conn

      alias LenraWeb.Router.Helpers, as: Routes
      plug :put_view, LenraWeb.BaseView
      action_fallback LenraWeb.FallbackController
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/lenra_web/templates",
        namespace: LenraWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  defp view_helpers do
    quote do
      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import LenraWeb.ErrorHelpers
      alias LenraWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

defmodule LenraWeb.Policy do
  @moduledoc """
    This macro give some helper functions to use the Bouncer library.
    It convert the `Bouncer.allow/4` function to a `allow/2` function using the conn.
    It call the `Bouncer.allow/4` function with :
    - The policy module from the option of `use LenraWeb.Policy, module: MyModule.Policy`
    - The current action from conn (:index, :create, :delete, :update...)
    - The current user from conn using `Guardian.Plug.current_resource/2`

    That way, we can just call the function allow(conn, params)
    instead of Bouncer.allow(MyModule.Policy, :index, Guardian.Plus.current_resource(conn), params)
  """

  defmacro __using__(opts \\ []) do
    policy_module = Keyword.get(opts, :module)

    alias Lenra.Guardian.Plug

    quote do
      @spec allow(any(), any()) :: :ok | {:error, atom()}
      def allow(conn, params \\ nil) do
        Bouncer.allow(
          unquote(policy_module),
          action_name(conn),
          Plug.current_resource(conn),
          params
        )
      end
    end
  end
end

defmodule LenraWeb.Policy.Default do
  @moduledoc """
    This macro define the 2 base rules for all Policy :
    -> Allow admin to do everything
    -> Deny everything else

    This macro is used as a base to define authorization policy.

    Important : Define your owh authorize/2 THEN use the `LenraWeb.Policy.Default` AFTER.
    Otherwise, the `LenraWeb.Policy.Default` rules will negate your next rules.
  """

  defmacro __using__(_) do
    quote do
      @behaviour Bouncer.Policy

      @impl Bouncer.Policy
      def authorize(_, %Lenra.User{role: :admin}, _), do: true
      def authorize(_, _, _), do: false

      defoverridable authorize: 3
    end
  end
end
