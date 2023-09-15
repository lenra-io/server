# defmodule ApplicationRunner.TextfieldValidatorTest do
#   use ApplicationRunner.ComponentCase

#   @moduledoc """
#     Test the "textfield.schema.json" schema
#   """

#   test "valid textfield", %{env_id: env_id} do
#     json = %{
#       "type" => "textfield",
#       "value" => "",
#       "onChanged" => %{
#         "_type" => "listener",
#         "name" => "anyaction",
#         "props" => %{
#           "number" => 10,
#           "value" => "value"
#         }
#       }
#     }

#     mock_root_and_run(json, env_id)

#     assert_success(%{
#       "type" => "textfield",
#       "value" => "",
#       "onChanged" => %{
#         "code" => _
#       }
#     })
#   end

#   test "valid textfield with no listener", %{env_id: env_id} do
#     json = %{
#       "type" => "textfield",
#       "value" => "test"
#     }

#     mock_root_and_run(json, env_id)

#     assert_success(^json)
#   end

#   test "invalid type textfield", %{env_id: env_id} do
#     json = %{
#       "type" => "textfields",
#       "value" => "test"
#     }

#     mock_root_and_run(json, env_id)
#     assert_error({:error, :invalid_ui, [{"Invalid component type", ""}]})
#   end

#   test "invalid textfield with no value", %{env_id: env_id} do
#     json = %{
#       "type" => "textfield"
#     }

#     mock_root_and_run(json, env_id)
#     assert_error({:error, :invalid_ui, [{"Required property value was not present.", ""}]})
#   end

#   test "invalid textfield with invalid name and props in listener", %{
#     env_id: env_id
#   } do
#     json = %{
#       "type" => "textfield",
#       "value" => "test",
#       "onChanged" => %{
#         "_type" => "listener",
#         "name" => 10,
#         "props" => ""
#       }
#     }

#     mock_root_and_run(json, env_id)

#     assert_error(
#       {:error, :invalid_ui,
#        [
#          {"Type mismatch. Expected String but got Integer.", "/onChanged/name"},
#          {"Type mismatch. Expected Object but got String.", "/onChanged/props"}
#        ]}
#     )
#   end

#   test "invalid textfield with invalid listener key", %{env_id: env_id} do
#     json = %{
#       "type" => "textfield",
#       "value" => "test",
#       "onClick" => %{
#         "_type" => "listener",
#         "name" => 42,
#         "props" => "machin"
#       }
#     }

#     mock_root_and_run(json, env_id)

#     assert_error(
#       {:error, :invalid_ui,
#        [
#          {"Schema does not allow additional properties.", "/onClick"}
#        ]}
#     )
#   end

#   test "valid textfield with empty value", %{env_id: env_id} do
#     json = %{
#       "type" => "textfield",
#       "value" => ""
#     }

#     mock_root_and_run(json, env_id)

#     assert_success(%{
#       "type" => "textfield",
#       "value" => ""
#     })
#   end
# end
