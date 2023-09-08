defmodule ApplicationRunner.JsonSchemata do
  use GenServer

  require Logger

  @moduledoc """
    `LenraServers.JsonValidator` is a GenServer that allow to validate a json schema with `LenraServers.JsonValidator.validate_ui/1`
  """

  # Client (api)
  @component_api_directory "priv/components-api/api"
  @component_api_root_file "component.schema.json"

  def get_schema_map(path) do
    GenServer.call(__MODULE__, {:get_schema_map, path})
  end

  def start_link(_) do
    Logger.debug("#{__MODULE__} Start")
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
    During init we load the root component from component_api (root defined in @component_api_directory).
  """
  @impl true
  def init(_) do
    root_json_directory =
      Application.app_dir(:application_runner, @component_api_directory) <>
        "/" <> @component_api_root_file

    {:ok, file_content} = File.read(root_json_directory)

    schemata_map =
      file_content
      |> Jason.decode!()
      |> ExComponentSchema.Schema.resolve()
      |> load_schema()

    {:ok, schemata_map}
  end

  def load_schema(root_schema) do
    Map.map(root_schema.refs, fn {id, ref} ->
      try do
        schema =
          parse_schema_ref(ref, ref["$id"])
          |> ExComponentSchema.Schema.resolve()

        schema_properties = ApplicationRunner.SchemaParser.parse(schema)

        Map.merge(%{schema: schema}, schema_properties)
      rescue
        e in ExComponentSchema.Schema.InvalidSchemaError ->
          reraise ExComponentSchema.Schema.InvalidSchemaError,
                  [message: "#{id} #{e.message}"],
                  __STACKTRACE__
      end
    end)
  end

  defp parse_schema_ref(%{"$ref" => v}, id) do
    concat_v =
      if String.contains?(Enum.at(v, 0), id) do
        Enum.concat(["#"], Enum.drop(v, 1))
      else
        v
      end
      |> Enum.join("/")

    if concat_v == "../component.schema.json" do
      %{"type" => "component"}
    else
      %{"$ref" => concat_v}
    end
  end

  defp parse_schema_ref(sub_value, id) do
    Map.new(sub_value, fn {k, v} ->
      case v do
        map when is_map(map) ->
          {k, parse_schema_ref(v, id)}

        value ->
          {k, value}
      end
    end)
  end

  def read_schema(path, root_location) do
    formatted_path =
      if root_location == @component_api_root_file do
        Path.join("/", path)
      else
        String.replace(root_location, ~r/\/.+\.schema\.json/, "/")
        |> Path.join(path)
      end

    "#{Application.app_dir(:application_runner, @component_api_directory)}/#{formatted_path}"
    |> File.read()
    |> case do
      {:ok, file_content} -> file_content
      {:error, _reason} -> raise "Cannot load json schema #{path}"
    end
    |> Jason.decode!()
  end

  def get_component_path(comp_type), do: "components/#{comp_type}.schema.json"

  @impl true
  def handle_call({:get_schema_map, path}, _from, schemata_map) do
    res =
      case Map.fetch(schemata_map, path) do
        :error -> {:error, [{"Invalid component type", "#"}]}
        {:ok, res} -> res
      end

    {:reply, res, schemata_map}
  end
end
