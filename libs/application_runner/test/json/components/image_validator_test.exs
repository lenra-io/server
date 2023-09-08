# defmodule ApplicationRunner.ImageValidatorTest do
#   use ApplicationRunner.ComponentCase

#   @moduledoc """
#     Test the "image.schema.json" schema
#   """

#   test "Valid image", %{env_id: env_id} do
#     json = %{
#       "type" => "image",
#       "src" => "download.jpeg"
#     }

#     mock_root_and_run(json, env_id)

#     assert_success(^json)
#   end

#   test "Valid image with width and height properties set", %{env_id: env_id} do
#     json = %{
#       "type" => "image",
#       "src" => "download.jpeg",
#       "width" => 120.0,
#       "height" => 120.0
#     }

#     mock_root_and_run(json, env_id)

#     assert_success(^json)
#   end

#   test "Invalid type for image", %{env_id: env_id} do
#     json = %{
#       "type" => "images",
#       "src" => "download.jpeg"
#     }

#     mock_root_and_run(json, env_id)
#     assert_error({:error, :invalid_ui, [{"Invalid component type", ""}]})
#   end

#   test "Invalid image with no path", %{env_id: env_id} do
#     json = %{
#       "type" => "image"
#     }

#     mock_root_and_run(json, env_id)
#     assert_error({:error, :invalid_ui, [{"Required property src was not present.", ""}]})
#   end

#   test "Invalid image wrong types on width and height", %{env_id: env_id} do
#     json = %{
#       "type" => "image",
#       "src" => "download.jpeg",
#       "width" => "wrong",
#       "height" => "wrong"
#     }

#     mock_root_and_run(json, env_id)

#     assert_error(
#       {:error, :invalid_ui,
#        [
#          {"Type mismatch. Expected Number but got String.", "/height"},
#          {"Type mismatch. Expected Number but got String.", "/width"}
#        ]}
#     )
#   end
# end
