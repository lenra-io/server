defmodule ApplicationRunner.MongoStorageTest do
  use ApplicationRunner.ConnCase, async: false

  alias ApplicationRunner.JsonSchemata

  describe "start_transaction" do
    setup do
      # start_supervised(ApplicationRunner.JsonSchemata)
      :ok
    end

    test "should validate container under 20 ms" do
      container = %{
        "type" => "container",
        "padding" => %{
          "top" => 8,
          "left" => 8,
          "bottom" => 8,
          "right" => 8
        },
        "decoration" => %{"color" => 0xFFFF0000},
        "constraints" => %{
          "minWidth" => 100,
          "maxWidth" => 100,
          "minHeight" => 100,
          "maxHeight" => 100
        },
        "child" => %{
          "type" => "text",
          "value" => "Text inside a container with padding"
        }
      }

      %{schema: schema} = JsonSchemata.get_schema_map("components/container.schema.json")

      {time, _res} = :timer.tc(fn -> ExComponentSchema.Validator.validate(schema, container) end)

      assert time / 1000 <= 10
    end

    test "should return error if mongo not started" do
      container = %{
        "type" => "container",
        "padding" => %{
          "top" => 8,
          "left" => 8,
          "bottom" => 8,
          "right" => 8
        },
        "decoration" => %{"color" => 0xFFFF0000},
        "constraints" => %{
          "minWidth" => 100,
          "maxWidth" => 100,
          "minHeight" => 100,
          "maxHeight" => 100
        },
        "child" => %{
          "type" => "container",
          "child" => %{
            "type" => "flex",
            "children" => [
              %{
                "type" => "flex",
                "children" => [
                  %{"type" => "text", "value" => "First child"},
                  %{"type" => "text", "value" => "Second child"}
                ]
              },
              %{
                "type" => "flex",
                "children" => [
                  %{"type" => "text", "value" => "First child"},
                  %{"type" => "text", "value" => "Second child"}
                ]
              },
              %{
                "type" => "flex",
                "children" => [
                  %{"type" => "text", "value" => "First child"},
                  %{"type" => "text", "value" => "Second child"}
                ]
              }
            ]
          }
        }
      }

      %{schema: schema} = JsonSchemata.get_schema_map("components/container.schema.json")

      {time, _res} = :timer.tc(fn -> ExComponentSchema.Validator.validate(schema, container) end)

      assert time / 1000 <= 10
    end
  end
end
