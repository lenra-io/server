defmodule LenraCommonWeb.ErrorView do
  defmacro __using__(_opts) do
    quote do
      use LenraCommonWeb, :view
      require Logger

      # If you want to customize a particular status code
      # for a certain format, you may uncomment below.
      def render(_error, %{reason: reason, message: message}) do
        %{"message" => message, "reason" => reason}
      end

      def render(_error, _assigns) do
        %{"message" => "Internal Server Error", "reason" => "format error"}
      end

      # By default, Phoenix returns the status message from
      # the template name. For example, "404.json" becomes
      # "Not Found".
      def template_not_found(_template, assigns) do
        Logger.debug("ERROR VIEW NOT FOUND")
        render("500.json", assigns)
      end
    end
  end
end
