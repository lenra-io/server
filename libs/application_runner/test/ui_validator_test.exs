# defmodule ApplicationRunner.UIValidatorTest do
#   use ApplicationRunner.ComponentCase

#   @moduledoc """
#     Test the `ApplicationRunner.UIValidator` module
#   """

#   @test_component_schema %{
#     "$defs" => %{
#       "listener" => %{
#         "properties" => %{
#           "_type" => %{"enum" => ["listener"]},
#           "name" => %{"type" => "string"},
#           "props" => %{"type" => "object"}
#         },
#         "required" => ["_type", "name"],
#         "type" => "listener"
#       }
#     },
#     "$id" => "test.schema.json",
#     "$schema" =>
#       "https://raw.githubusercontent.com/lenra-io/ex_component_schema/beta/priv/static/draft-lenra.json",
#     "additionalProperties" => false,
#     "description" => "Element used to test the Lenra Draft",
#     "properties" => %{
#       "disabled" => %{
#         "description" => "Whether the component should be disabled or not",
#         "type" => "boolean"
#       },
#       "onDrag" => %{"$ref" => "#/$defs/listener"},
#       "onPressed" => %{"$ref" => "#/$defs/listener"},
#       "type" => %{"description" => "The type of the element", "enum" => ["test"]},
#       "value" => %{
#         "description" => "the value displayed in the element",
#         "type" => "string"
#       },
#       "leftWidget" => %{"type" => "component"},
#       "rightWidget" => %{"type" => "component"},
#       "leftMenu" => %{"type" => "array", "items" => %{"type" => "component"}},
#       "rightMenu" => %{"type" => "array", "items" => %{"type" => "component"}}
#     },
#     "required" => ["type", "value"],
#     "title" => "Test Component",
#     "type" => "component"
#   }

#   ApplicationRunner.JsonSchemata.load_raw_schema(@test_component_schema, "test")

#   test "valide basic UI", %{env_id: env_id} do
#     json = %{
#       "type" => "text",
#       "value" => "Txt test"
#     }

#     mock_root_and_run(json, env_id)
#     assert_success(^json)
#   end

#   test "bug LENRA-130", %{env_id: env_id} do
#     json = %{
#       "type" => "flex",
#       "children" => [
#         %{
#           "type" => "flex",
#           "children" => [
#             %{
#               "type" => "textfield",
#               "value" => "",
#               "onChanged" => %{
#                 "_type" => "listener",
#                 "name" => "Category.setName"
#               }
#             },
#             %{
#               "type" => "button",
#               "text" => "Save",
#               "onPressed" => %{
#                 "_type" => "listener",
#                 "name" => "Category.save"
#               }
#             }
#           ]
#         },
#         %{
#           "type" => "flex",
#           "children" => [
#             %{
#               "type" => "button",
#               "text" => "+",
#               "onPressed" => %{
#                 "_type" => "listener",
#                 "name" => "Category.addField"
#               }
#             }
#           ]
#         }
#       ]
#     }

#     mock_root_and_run(json, env_id)

#     assert_error({
#       :error,
#       :invalid_ui,
#       [
#         {"Schema does not allow additional properties.", "/children/0/children/0/onChanged/name"},
#         {"Required property name was not present.", "/children/0/children/0/onChanged"},
#         {"Schema does not allow additional properties.", "/children/0/children/1/onPressed/name"},
#         {"Required property name was not present.", "/children/0/children/1/onPressed"},
#         {"Schema does not allow additional properties.", "/children/1/children/0/onPressed/name"},
#         {"Required property name was not present.", "/children/1/children/0/onPressed"}
#       ]
#     })
#   end

#   test "multiple type error", %{env_id: env_id} do
#     json = %{
#       "type" => "flex",
#       "children" => [
#         %{"value" => "machin"},
#         %{"value" => "truc"},
#         %{"type" => "truc"},
#         %{"type" => "machin"},
#         %{"type" => "text"}
#       ]
#     }

#     mock_root_and_run(json, env_id)

#     assert_error({
#       :error,
#       :invalid_ui,
#       [
#         {"Type mismatch. Expected Component but got Object.", "/children/0"},
#         {"Type mismatch. Expected Component but got Object.", "/children/1"}
#       ]
#     })
#   end
# end
