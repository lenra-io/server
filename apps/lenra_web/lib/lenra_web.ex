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
      use LenraCommonWeb, :controller

      # credo:disable-for-next-line Credo.Check.Readability.AliasAs
      alias LenraWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use LenraCommonWeb, :view

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
      use LenraCommonWeb, :view_helpers

      # credo:disable-for-next-line Credo.Check.Readability.AliasAs
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
    - The current user from conn using `LenraWeb.Auth.current_resource/2`

    That way, we can just call the function allow(conn, params)
    instead of Bouncer.allow(MyModule.Policy, :index, LenraWeb.Auth.current_resource(conn), params)
  """

  defmacro __using__(opts \\ []) do
    policy_module = Keyword.get(opts, :module)

    alias LenraWeb.Auth

    quote do
      @spec allow(any(), any()) :: :ok | {:error, atom()}
      def allow(conn, params \\ nil) do
        Bouncer.allow(
          unquote(policy_module),
          action_name(conn),
          Auth.current_resource(conn),
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
      def authorize(_action, %Lenra.Accounts.User{role: :admin}, _data), do: true
      def authorize(_action, _user, _data), do: false

      defoverridable authorize: 3
    end
  end
end
