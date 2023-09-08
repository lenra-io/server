# defmodule ApplicationRunner.TextValidatorTest do
#   use ApplicationRunner.ComponentCase

#   @moduledoc """
#     Test the "text.schema.json" schema
#   """

#   test "valide text component", %{env_id: env_id} do
#     json = %{
#       "type" => "text",
#       "value" => "Txt test"
#     }

#     mock_root_and_run(json, env_id)

#     assert_success(^json)
#   end

#   test "valide text empty value", %{env_id: env_id} do
#     json = %{
#       "type" => "text",
#       "value" => ""
#     }

#     mock_root_and_run(json, env_id)

#     assert_success(^json)
#   end

#   test "invalide text type", %{env_id: env_id} do
#     json = %{
#       "type" => "texts",
#       "value" => ""
#     }

#     mock_root_and_run(json, env_id)
#     assert_error({:error, :invalid_ui, [{"Invalid component type", ""}]})
#   end

#   test "invalid text no value", %{env_id: env_id} do
#     json = %{
#       "type" => "text"
#     }

#     mock_root_and_run(json, env_id)
#     assert_error({:error, :invalid_ui, [{"Required property value was not present.", ""}]})
#   end

#   test "invalid text no string value type", %{env_id: env_id} do
#     json = %{
#       "type" => "text",
#       "value" => 42
#     }

#     mock_root_and_run(json, env_id)

#     assert_error(
#       {:error, :invalid_ui, [{"Type mismatch. Expected String but got Integer.", "/value"}]}
#     )
#   end
# end
