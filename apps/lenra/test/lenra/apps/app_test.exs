defmodule Lenra.Apps.AppTest do
  use Lenra.RepoCase, async: true

  alias Lenra.Apps.App

  @valide_data %{name: "Test", color: "FF0000", icon: 1111, repository: "repository"}
  @invalide_data %{name: nil, color: nil, icon: nil, repository: nil}

  describe "lenra_application" do
    test "new/2 with valid data creates a lenra_application" do
      assert %{changes: app, valid?: true} = App.new(1, @valide_data)
      assert app.name == @valide_data.name
      assert app.color == @valide_data.color
      assert app.icon == @valide_data.icon
      assert app.repository == @valide_data.repository
    end

    test "new/2 with invalid data creates a lenra_application" do
      assert %{changes: _app, valid?: false} = App.new(1, @invalide_data)
    end
  end
end
