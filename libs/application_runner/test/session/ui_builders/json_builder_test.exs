defmodule ApplicationRunner.Session.UiBuilders.JsonBuilderTest do
  use ExUnit.Case
  doctest ApplicationRunner.Session.UiBuilders.JsonBuilder

  alias ApplicationRunner.Session.UiBuilders.JsonBuilder
  alias ApplicationRunner.Session.UiBuilders.UiBuilderAdapter
  alias ApplicationRunner.Environment.ViewUid
  alias ApplicationRunner.Session.Metadata
  alias ApplicationRunner.Ui.Context

  import Mock

  @session_uuid Ecto.UUID.generate()

  setup_with_mocks([
    {UiBuilderAdapter, [:passthrough],
     [
       handle_view: fn _module, _session_metadata, _component, ui_context, _view_uid ->
         {:ok, %{"_type" => "view", "id" => "viewID"}, ui_context}
       end
     ]},
    {ApplicationRunner.Session.RouteServer, [:passthrough],
     [
       build_listener: fn _session_metadata, _component ->
         {:ok, %{"_type" => "listener", "code" => "listenerCode"}}
       end
     ]}
  ]) do
    :ok
  end

  describe "build_components/4" do
    test "string" do
      # Prepare
      session_metadata = %Metadata{
        env_id: 1,
        session_id: @session_uuid,
        user_id: nil,
        roles: ["guest"],
        function_name: "test",
        context: %{}
      }

      ui_context = Context.new()

      view_uid = %ViewUid{
        name: "test_view",
        props: nil,
        query_parsed: nil,
        query_transformed: nil,
        coll: nil,
        context: nil,
        prefix_path: "",
        projection: %{}
      }

      # Act
      result =
        JsonBuilder.build_components(
          session_metadata,
          "coucou",
          ui_context,
          view_uid
        )

      # Assert
      assert {:ok, component, _ui_context} = result

      # Add your assertions here
      assert component == "coucou"

      assert_not_called(UiBuilderAdapter.handle_view(:_, :_, :_, :_, :_))
      assert_not_called(ApplicationRunner.Session.RouteServer.build_listener(:_, :_))
    end

    test "array" do
      # Prepare
      session_metadata = %Metadata{
        env_id: 1,
        session_id: @session_uuid,
        user_id: nil,
        roles: ["guest"],
        function_name: "test",
        context: %{}
      }

      ui_context = Context.new()

      view_uid = %ViewUid{
        name: "test_view",
        props: nil,
        query_parsed: nil,
        query_transformed: nil,
        coll: nil,
        context: nil,
        prefix_path: "",
        projection: %{}
      }

      # Act
      result =
        JsonBuilder.build_components(
          session_metadata,
          ["coucou"],
          ui_context,
          view_uid
        )

      # Assert
      assert {:ok, component, _ui_context} = result

      # Add your assertions here
      assert component == ["coucou"]

      assert_not_called(UiBuilderAdapter.handle_view(:_, :_, :_, :_, :_))
      assert_not_called(ApplicationRunner.Session.RouteServer.build_listener(:_, :_))
    end

    test "basic object" do
      # Prepare
      session_metadata = %Metadata{
        env_id: 1,
        session_id: @session_uuid,
        user_id: nil,
        roles: ["guest"],
        function_name: "test",
        context: %{}
      }

      ui_context = Context.new()

      view_uid = %ViewUid{
        name: "test_view",
        props: nil,
        query_parsed: nil,
        query_transformed: nil,
        coll: nil,
        context: nil,
        prefix_path: "",
        projection: %{}
      }

      # Act
      result =
        JsonBuilder.build_components(
          session_metadata,
          %{"key" => "value"},
          ui_context,
          view_uid
        )

      # Assert
      assert {:ok, component, _ui_context} = result

      # Add your assertions here
      assert component == %{"key" => "value"}

      assert_not_called(UiBuilderAdapter.handle_view(:_, :_, :_, :_, :_))
      assert_not_called(ApplicationRunner.Session.RouteServer.build_listener(:_, :_))
    end

    test "simple view component" do
      # Prepare
      session_metadata = %Metadata{
        env_id: 1,
        session_id: @session_uuid,
        user_id: nil,
        roles: ["guest"],
        function_name: "test",
        context: %{}
      }

      ui_context = Context.new()

      view_uid = %ViewUid{
        name: "test_view",
        props: nil,
        query_parsed: nil,
        query_transformed: nil,
        coll: nil,
        context: nil,
        prefix_path: "",
        projection: %{}
      }

      # Act
      result =
        JsonBuilder.build_components(
          session_metadata,
          %{"_type" => "view", "name" => "my_view"},
          ui_context,
          view_uid
        )

      # Assert
      assert {:ok, component, _ui_context} = result

      # Add your assertions here
      assert component == %{"_type" => "view", "id" => "viewID"}

      assert_called(UiBuilderAdapter.handle_view(:_, :_, :_, :_, :_))
      assert_not_called(ApplicationRunner.Session.RouteServer.build_listener(:_, :_))
    end

    test "complete view component" do
      # Prepare
      session_metadata = %Metadata{
        env_id: 1,
        session_id: @session_uuid,
        user_id: nil,
        roles: ["guest"],
        function_name: "test",
        context: %{}
      }

      ui_context = Context.new()

      view_uid = %ViewUid{
        name: "test_view",
        props: nil,
        query_parsed: nil,
        query_transformed: nil,
        coll: nil,
        context: nil,
        prefix_path: "",
        projection: %{}
      }

      # Act
      result =
        JsonBuilder.build_components(
          session_metadata,
          %{
            "_type" => "view",
            "name" => "my_view",
            "props" => %{"key" => "value"},
            "find" => %{"coll" => "my_collection", "query" => %{"key" => "value"}},
            "context" => %{"me" => true}
          },
          ui_context,
          view_uid
        )

      # Assert
      assert {:ok, component, _ui_context} = result

      # Add your assertions here
      assert component == %{"_type" => "view", "id" => "viewID"}

      assert_called(UiBuilderAdapter.handle_view(:_, :_, :_, :_, :_))
      assert_not_called(ApplicationRunner.Session.RouteServer.build_listener(:_, :_))
    end

    test "simple listener component" do
      # Prepare
      session_metadata = %Metadata{
        env_id: 1,
        session_id: @session_uuid,
        user_id: nil,
        roles: ["guest"],
        function_name: "test",
        context: %{}
      }

      ui_context = Context.new()

      view_uid = %ViewUid{
        name: "test_view",
        props: nil,
        query_parsed: nil,
        query_transformed: nil,
        coll: nil,
        context: nil,
        prefix_path: "",
        projection: %{}
      }

      # Act
      result =
        JsonBuilder.build_components(
          session_metadata,
          %{
            "_type" => "listener",
            "name" => "my_listener"
          },
          ui_context,
          view_uid
        )

      # Assert
      assert {:ok, component, _ui_context} = result

      # Add your assertions here
      assert component == %{"_type" => "listener", "code" => "listenerCode"}

      assert_not_called(UiBuilderAdapter.handle_view(:_, :_, :_, :_, :_))
      assert_called(ApplicationRunner.Session.RouteServer.build_listener(:_, :_))
    end

    test "complete listener component" do
      # Prepare
      session_metadata = %Metadata{
        env_id: 1,
        session_id: @session_uuid,
        user_id: nil,
        roles: ["guest"],
        function_name: "test",
        context: %{}
      }

      ui_context = Context.new()

      view_uid = %ViewUid{
        name: "test_view",
        props: nil,
        query_parsed: nil,
        query_transformed: nil,
        coll: nil,
        context: nil,
        prefix_path: "",
        projection: %{}
      }

      # Act
      result =
        JsonBuilder.build_components(
          session_metadata,
          %{
            "_type" => "listener",
            "name" => "my_listener",
            "props" => %{"key" => "value"}
          },
          ui_context,
          view_uid
        )

      # Assert
      assert {:ok, component, _ui_context} = result

      # Add your assertions here
      assert component == %{"_type" => "listener", "code" => "listenerCode"}

      assert_not_called(UiBuilderAdapter.handle_view(:_, :_, :_, :_, :_))
      assert_called(ApplicationRunner.Session.RouteServer.build_listener(:_, :_))
    end

    test "complexe object with components" do
      # Prepare
      session_metadata = %Metadata{
        env_id: 1,
        session_id: @session_uuid,
        user_id: nil,
        roles: ["guest"],
        function_name: "test",
        context: %{}
      }

      ui_context = Context.new()

      view_uid = %ViewUid{
        name: "test_view",
        props: nil,
        query_parsed: nil,
        query_transformed: nil,
        coll: nil,
        context: nil,
        prefix_path: "",
        projection: %{}
      }

      # Act
      result =
        JsonBuilder.build_components(
          session_metadata,
          %{
            "elements" => ["coucou", %{"_type" => "view", "name" => "my_view"}],
            "on_click" => %{"_type" => "listener", "name" => "my_listener"}
          },
          ui_context,
          view_uid
        )

      # Assert
      assert {:ok, component, _ui_context} = result

      # Add your assertions here
      assert component == %{
               "elements" => ["coucou", %{"_type" => "view", "id" => "viewID"}],
               "on_click" => %{"_type" => "listener", "code" => "listenerCode"}
             }

      assert_called(UiBuilderAdapter.handle_view(:_, :_, :_, :_, :_))
      assert_called(ApplicationRunner.Session.RouteServer.build_listener(:_, :_))
    end
  end
end
