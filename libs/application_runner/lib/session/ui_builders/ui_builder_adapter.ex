defmodule ApplicationRunner.Session.UiBuilders.UiBuilderAdapter do
  @moduledoc """
  ApplicationRunner.UiBuilderAdapter provides the callback nedded to build a given UI.
  """

  alias ApplicationRunner.Environment.ViewUid
  alias ApplicationRunner.Session
  alias LenraCommon.Errors

  @type common_error :: Errors.BusinessError.t() | Errors.TechnicalError.t()

  @callback build_ui(Session.Metadata.t(), ViewUid.t()) ::
              {:ok, map()} | {:error, common_error()}

  @callback get_routes(number(), {:array, :string}) :: list(binary())
end
