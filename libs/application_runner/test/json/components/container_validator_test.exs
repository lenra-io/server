# defmodule ApplicationRunner.ContainerValidatorTest do
#   use ApplicationRunner.ComponentCase

#   alias ApplicationRunner.{
#     ApplicationRunnerAdapter,
#     EnvManagers,
#     SessionManagers
#   }

#   @moduledoc """
#     Test the "container.schema.json" schema
#   """

#   test "valid container", %{env_id: env_id} do
#     json = %{
#       "type" => "container",
#       "child" => %{
#         "type" => "text",
#         "value" => "foo"
#       }
#     }

#     mock_root_and_run(json, env_id)

#     assert_success(^json)
#   end

#   test "valid container with border", %{env_id: env_id} do
#     json = %{
#       "type" => "container",
#       "child" => %{
#         "type" => "text",
#         "value" => "foo"
#       },
#       "border" => %{
#         "top" => %{
#           "width" => 2,
#           "color" => 0xFFFFFFFF
#         },
#         "left" => %{
#           "width" => 2,
#           "color" => 0xFFFFFFFF
#         },
#         "bottom" => %{
#           "width" => 2,
#           "color" => 0xFFFFFFFF
#         },
#         "right" => %{
#           "width" => 2,
#           "color" => 0xFFFFFFFF
#         }
#       }
#     }

#     mock_root_and_run(json, env_id)

#     assert_success(^json)
#   end

#   test "valid container with borderRadius", %{env_id: env_id} do
#     json = %{
#       "type" => "container",
#       "child" => %{
#         "type" => "text",
#         "value" => "foo"
#       },
#       "decoration" => %{
#         "borderRadius" => %{
#           "topLeft" => %{"x" => 5.0, "y" => 5.0},
#           "topRight" => %{"x" => 5.0, "y" => 5.0},
#           "bottomLeft" => %{"x" => 5.0, "y" => 5.0},
#           "bottomRight" => %{"x" => 5.0, "y" => 5.0}
#         }
#       }
#     }

#     mock_root_and_run(json, env_id)

#     assert_success(^json)
#   end

#   test "invalid container forgotten child", %{env_id: env_id} do
#     json = %{
#       "type" => "container"
#     }

#     mock_root_and_run(json, env_id)

#     assert_error({:error, :invalid_ui, [{"Required property child was not present.", ""}]})
#   end

#   test "invalid container border", %{env_id: env_id} do
#     json = %{
#       "type" => "container",
#       "child" => %{
#         "type" => "text",
#         "value" => "foo"
#       },
#       "border" => %{
#         "top" => %{
#           "width" => "invalid",
#           "color" => 0xFFFFFFFF
#         },
#         "left" => %{
#           "width" => "invalid",
#           "color" => 0xFFFFFFFF
#         },
#         "bottom" => %{
#           "width" => "invalid",
#           "color" => 0xFFFFFFFF
#         },
#         "right" => %{
#           "width" => "invalid",
#           "color" => 0xFFFFFFFF
#         }
#       }
#     }

#     mock_root_and_run(json, env_id)

#     assert_error(
#       {:error, :invalid_ui,
#        [
#          {"Type mismatch. Expected Number but got String.", "/border/bottom/width"},
#          {"Type mismatch. Expected Number but got String.", "/border/left/width"},
#          {"Type mismatch. Expected Number but got String.", "/border/right/width"},
#          {"Type mismatch. Expected Number but got String.", "/border/top/width"}
#        ]}
#     )
#   end
# end
