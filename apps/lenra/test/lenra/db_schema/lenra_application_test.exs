defmodule Lenra.LenraApplicationTest do
  use Lenra.RepoCase, async: true

  alias Lenra.LenraApplication

  @valide_data %{name: "Test", service_name: "test", color: "FF0000", icon: 1111, repository: "repository"}
  @invalide_data %{name: nil, service_name: nil, color: nil, icon: nil, repository: nil}

  describe "lenra_appliaction" do
    test "new/2 with valid data creates a lenra_application" do
      assert %{changes: app, valid?: true} = LenraApplication.new(1, @valide_data)
      assert app.name == @valide_data.name
      assert app.service_name == @valide_data.service_name
      assert app.color == @valide_data.color
      assert app.icon == @valide_data.icon
      assert app.repository == @valide_data.repository
    end

    test "new/2 with invalid data creates a lenra_application" do
      assert %{changes: _app, valid?: false} = LenraApplication.new(1, @invalide_data)
    end
  end
end
