# defmodule ApplicationRunner.FlexValidatorTest do
#   use ApplicationRunner.ComponentCase

#   @moduledoc """
#     Test the "flex.schema.json" schema
#   """

#   test "valid flex", %{env_id: env_id} do
#     json = %{
#       "type" => "flex",
#       "children" => [
#         %{
#           "type" => "text",
#           "value" => "Txt test"
#         }
#       ]
#     }

#     mock_root_and_run(json, env_id)

#     assert_success(^json)
#   end

#   test "valid empty flex", %{env_id: env_id} do
#     json = %{
#       "type" => "flex",
#       "children" => []
#     }

#     mock_root_and_run(json, env_id)

#     assert_success(^json)
#   end

#   test "invalid flex type", %{env_id: env_id} do
#     json = %{
#       "type" => "flexes",
#       "children" => []
#     }

#     mock_root_and_run(json, env_id)

#     assert_error({:error, :invalid_ui, [{"Invalid component type", ""}]})
#   end

#   test "invalide component inside the flex", %{env_id: env_id} do
#     json = %{
#       "type" => "flex",
#       "children" => [
#         %{
#           "type" => "text",
#           "value" => "Txt test"
#         },
#         %{
#           "type" => "New"
#         }
#       ]
#     }

#     mock_root_and_run(json, env_id)

#     assert_error({:error, :invalid_ui, [{"Invalid component type", "/children/1"}]})
#   end

#   test "invalid flex with no children property", %{env_id: env_id} do
#     json = %{
#       "type" => "flex"
#     }

#     mock_root_and_run(json, env_id)

#     assert_error({:error, :invalid_ui, [{"Required property children was not present.", ""}]})
#   end

#   def my_widget(_, _) do
#     %{
#       "type" => "flex",
#       "children" => []
#     }
#   end

#   def root(_, _) do
#     %{
#       "type" => "widget",
#       "name" => "myWidget"
#     }
#   end

#   def init_data(_, _) do
#     %{
#       "type" => "widget",
#       "name" => "myWidget"
#     }
#   end

#   @tag mock: %{
#          widgets: %{
#            "myWidget" => &__MODULE__.my_widget/2,
#            "root" => &__MODULE__.root/2
#          },
#          listeners: %{"onSessionStart" => &__MODULE__.init_data/2}
#        }
#   test "valid flex with empty children in widget", %{} do
#     refute_receive({:ui, _})
#     refute_receive({:error, _})
#   end
# end
