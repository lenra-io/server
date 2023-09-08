alias ApplicationRunner.JsonValidator

schema = JsonValidator.resolve_schema("ui.schema.json")

root = fn json -> %{
    "root" => json
  }
end

text = %{
  "type" => "text",
  "value" => "machin"
}

error_text = %{
  "type" => "text"
}

button = %{
  "type" => "button",
  "value" => "azaz",
  "listeners" => %{
    "onClick" => %{
      "action" => "anyaction",
      "props" => %{
        "number" => 10,
        "value" => "value"
      }
    }
  }
}

container = %{
  "type" => "container",
  "children" => [
    text,
    text,
    text,
    button,
    button,
    button
  ]
}

error_container = %{
  "type" => "container",
  "children" => [
    text,
    text,
    error_text,
    button,
    button,
    button
  ]
}

complexe_container = Enum.reduce(1..20, container,  fn _, acc ->
  Map.replace!(acc, "children", [container | acc["children"]])
end)

{:ok, _} = JsonValidator.validate_json(schema, root.(text))
{:error, _} = JsonValidator.validate_json(schema, root.(error_text))
{:ok, _} = JsonValidator.validate_json(schema, root.(container))
{:error, _} = JsonValidator.validate_json(schema, root.(error_container))
{:ok, _} = JsonValidator.validate_json(schema, root.(complexe_container))

Benchee.run(
  %{
    "simple text" => fn -> JsonValidator.validate_json(schema, root.(text)) end,
    "error simple text" => fn -> JsonValidator.validate_json(schema, root.(error_text)) end,
    "container with 3 buttons and 3 texts" => fn -> JsonValidator.validate_json(schema, root.(container)) end,
    "error container with 3 buttons and 3 texts" => fn -> JsonValidator.validate_json(schema, root.(error_container)) end,
    "complexe container" => fn -> JsonValidator.validate_json(schema, root.(complexe_container)) end
  },
  time: 5,
  memory_time: 2
)
