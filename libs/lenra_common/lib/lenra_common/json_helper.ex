defmodule LenraCommon.JsonHelper do
  @moduledoc """
    JsonHelper gives some function that can help with json maps
  """
  require Logger
  alias LenraCommon.Errors.BusinessError

  @doc """
    get_in_json allow to get in json map value by path, ex:

    ```
    my_json_map = %{
      "lvl1" => %{
        "lvl2" => %{
          "value" => "test"
        }
      }
    }

    get_in_json(my_json_map, ["lvl1", "lvl2", "value"])
    ```
  """
  def get_in_json(nil, [_]), do: Logger.debug(BusinessError.nil_json_tuple())
  def get_in_json(nil, [_ | t]), do: get_in_json(nil, t)

  def get_in_json(data, [h]) when is_bitstring(h) and is_list(data),
    do: get_in_list(data, h)

  def get_in_json(data, [h]) when is_bitstring(h), do: data[h]

  def get_in_json(data, [h | t]) when is_bitstring(h) and is_list(data),
    do: get_in_json(get_in_list(data, h), t)

  def get_in_json(data, [h | t]) when is_bitstring(h),
    do: get_in_json(data[h], t)

  defp get_in_list(data, h) do
    case Integer.parse(h) do
      :error ->
        Logger.debug(BusinessError.integer_array_index([data, h]))

      {number, _} ->
        Enum.at(data, number)
    end
  end
end
