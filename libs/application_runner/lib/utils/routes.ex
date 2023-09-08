defmodule ApplicationRunner.Utils.Routes do
  @moduledoc """
    This is a utility module related to parsing and matching routes.
  """
  alias ApplicationRunner.Errors.BusinessError
  alias LenraCommon.Errors, as: LC

  @doc """
    This route check if the path matches the route.
    If it matches, return the route_params map.
    /route/:id/:id2 matche with /route/42/1337 and the route_params are :
    %{"id" => 42, "id2" => 1337}
  """
  @spec match_route(String.t(), String.t()) :: {:ok, map} | {:error, LC.BusinessError.t()}
  def match_route(route, path) do
    route_parts = route |> String.trim("/") |> String.split("/")
    path_parts = path |> String.trim("/") |> String.split("/")

    if Enum.count(route_parts) == Enum.count(path_parts) do
      extract_route_params(route_parts, path_parts)
    else
      BusinessError.route_does_not_exist_tuple(path)
    end
  end

  defp extract_route_params(route_parts, path_parts) do
    Enum.zip(route_parts, path_parts)
    |> Enum.reduce_while({:ok, %{}}, fn
      {":" <> route_part, path_part}, {:ok, route_params} ->
        {:cont, {:ok, Map.put(route_params, route_part, try_parse(path_part))}}

      {part, part}, res ->
        {:cont, res}

      {_route_part, _path_part}, _route_params ->
        {:halt, BusinessError.route_does_not_exist_tuple()}
    end)
  end

  defp try_parse("true"), do: true
  defp try_parse("false"), do: false

  defp try_parse(value) do
    with {:nope, value} <- parse_interger(value),
         {:nope, value} <- parse_float(value),
         {:nope, value} <- parse_mongo_object_id(value) do
      value
    else
      {:success, res} -> res
    end
  end

  defp parse_mongo_object_id(value) do
    case BSON.ObjectId.decode(value) do
      {:ok, res} -> {:success, res}
      :error -> {:nope, value}
    end
  end

  defp parse_interger(value) do
    case Integer.parse(value) do
      :error -> {:nope, value}
      {res, ""} -> {:success, res}
      {_res, _rest} -> {:nope, value}
    end
  end

  defp parse_float(value) do
    case Float.parse(value) do
      :error -> {:nope, value}
      {res, ""} -> {:success, res}
      {_res, _rest} -> {:nope, value}
    end
  end
end
