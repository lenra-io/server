defmodule ApplicationRunner.Ui.Context do
  @moduledoc """
    The UI Context that contain all views and listeners information
  """

  defstruct [
    :views_map,
    :listeners_map
  ]

  @type t :: %__MODULE__{
          views_map: map(),
          listeners_map: map()
        }

  def new do
    %__MODULE__{views_map: %{}, listeners_map: %{}}
  end
end
