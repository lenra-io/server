defmodule LenraServers.PasswordServicesTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Repo, PasswordServices}

  @moduledoc """
    Test the Password services
  """

  test "The password code should be deleted after password modification" do
    {:ok, %{inserted_user: user}} = register_john_doe()
    {:ok, _} = PasswordServices.send_password_code(user)
    user = Repo.preload(user, [:password_code])
    password_code = user.password_code
    assert not is_nil(password_code)

    assert {:ok, ^password_code} = PasswordServices.check_password_code_valid(user, password_code.code)
    assert {:ok, _} = PasswordServices.update_lost_password(user, password_code, %{"password" => "MyNewPassword42!"})

    # Force reload the password code
    user = Repo.preload(user, [:password_code], force: true)
    assert is_nil(user.password_code)
  end
end
