defmodule ApplicationRunner.Session.UiBuilders.UiBuilderAdapterTest do
  use ExUnit.Case
  doctest ApplicationRunner.Session.UiBuilders.UiBuilderAdapter

  alias ApplicationRunner.Environment.ViewUid
  alias ApplicationRunner.Session.Metadata
  alias ApplicationRunner.Session.RouteServer
  alias ApplicationRunner.Session.UiBuilders.UiBuilderAdapter
  alias ApplicationRunner.Ui.Context

  import Mock

  @session_uuid Ecto.UUID.generate()

  describe "build_ui/3" do
    test "basic component" do
      with_mock RouteServer,
        fetch_view: fn _session_metadata, _view_uid -> {:ok, %{"count" => 1}} end do
        # Prepare
        session_metadata = %Metadata{
          env_id: 1,
          session_id: @session_uuid,
          user_id: nil,
          roles: ["guest"],
          function_name: "test",
          context: %{}
        }

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

        adapter = ApplicationRunner.FakeUiBuilderAdapter

        # Act
        result = UiBuilderAdapter.build_ui(adapter, session_metadata, view_uid)

        # Assert
        assert {:ok, ui} = result

        # Add your assertions here
        assert ui == %{"count" => 1}

        assert called(RouteServer.fetch_view(:_, :_))
      end
    end
  end

  describe "handle_view/5" do
    test "basic view" do
      view_result = %{"count" => 1}

      new_view_uid = %ViewUid{
        name: "test_view_new",
        props: nil,
        query_parsed: nil,
        query_transformed: nil,
        coll: nil,
        context: nil,
        prefix_path: "",
        projection: %{}
      }

      with_mock RouteServer,
        fetch_view: fn _session_metadata, _view_uid -> {:ok, view_result} end,
        extract_find: fn _component, _find -> {nil, nil, nil} end,
        create_view_uid: fn _session_metadata,
                            _name,
                            _find,
                            _query_params,
                            _props,
                            _context,
                            _context_projection,
                            _prefix_path ->
          {:ok, new_view_uid}
        end do
        # Prepare
        session_metadata = %Metadata{
          env_id: 1,
          session_id: @session_uuid,
          user_id: nil,
          roles: ["guest"],
          function_name: "test",
          context: %{}
        }

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

        ui_context = Context.new()
        component = %{"_type" => "view", "name" => "test_view_new"}
        adapter = ApplicationRunner.FakeUiBuilderAdapter

        # Act
        result = UiBuilderAdapter.handle_view(adapter, session_metadata, component, ui_context, view_uid)

        # Assert
        assert {:ok, view, updated_context} = result

        # Add your assertions here
        assert %{"_type" => "view", "name" => "test_view_new", "id" => new_view_uid} = view

        assert updated_context.views_map[new_view_uid] == view_result

        assert called(RouteServer.fetch_view(:_, :_))
      end
    end
  end

  describe "handle_listener/5" do
    test "basic listener" do
      with_mock RouteServer,
        build_listener: fn _session_metadata, _component -> {:ok, %{"_type" => "listener", "code" => "the_code"}} end do
        # Prepare
        session_metadata = %Metadata{
          env_id: 1,
          session_id: @session_uuid,
          user_id: nil,
          roles: ["guest"],
          function_name: "test",
          context: %{}
        }

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

        ui_context = %Context{}
        component = %{"_type" => "listener", "name" => "test_listener"}
        adapter = ApplicationRunner.FakeUiBuilderAdapter

        # Act
        result = UiBuilderAdapter.handle_listener(adapter, session_metadata, component, ui_context, view_uid)

        # Assert
        assert {:ok, listener, _updated_context} = result

        # Add your assertions here
        assert listener == %{"_type" => "listener", "code" => "the_code"}

        assert called(RouteServer.build_listener(:_, component))
      end
    end
  end
end
