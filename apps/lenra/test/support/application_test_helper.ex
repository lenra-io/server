# defmodule ApplicationTestHelper do
#  @moduledoc """
#    Test helper for user
#  """
#
#  alias Lenra.{LenraApplicationServices}
#
#  @minesweeper_app_params %{
#    name: "mine-sweeper",
#    service_name: "mine-sweeper",
#    color: "FFFFFF",
#    icon: "60189"
#  }
#
#  def param_app(idx) do
#    %{
#      name: "mine-sweeper-#{idx}",
#      service_name: "mine-sweeper-#{idx}",
#      color: "FFFFFF",
#      icon: "60189"
#    }
#  end
#
#  def register_app(params, user_id) do
#    LenraApplicationServices.create(user_id, params)
#  end
#
#  def register_app_nb(user_id, idx) do
#    LenraApplicationServices.create(user_id, param_app(idx))
#  end
#
#  def register_minesweeper(user_id, changes \\ %{}) do
#    @minesweeper_app_params
#    |> Map.merge(changes)
#    |> register_app(user_id)
#  end
# end
#
