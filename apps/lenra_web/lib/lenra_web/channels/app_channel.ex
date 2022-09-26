defmodule LenraWeb.AppChannel do
  @moduledoc """
    LenraWeb.AppChannel use ApplicationRunner.AppChannel and pass the adapter module
  """
  use ApplicationRunner.AppChannel, adapter: LenraWeb.AppAdapter
end
