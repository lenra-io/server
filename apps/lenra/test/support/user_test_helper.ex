defmodule UserTestHelper do
  @moduledoc """
    Test helper for user
  """

  alias Lenra.UserServices

  @john_doe_user_params %{
    "first_name" => "John",
    "last_name" => "Doe",
    "email" => "john.doe@lenra.fr",
    "password" => "Johndoe@thefirst",
    "password_confirmation" => "Johndoe@thefirst"
  }

  def param_user(idx) do
    %{
      "first_name" => "John #{idx}",
      "last_name" => "Doe #{idx}",
      "email" => "john.doe#{idx}@lenra.fr",
      "password" => "Johndoe@thefirst",
      "password_confirmation" => "Johndoe@thefirst"
    }
  end

  def register_user(params) do
    UserServices.register(params, params["role"])
  end

  def register_user_nb(idx, role) do
    UserServices.register(param_user(idx), role)
  end

  def register_john_doe(changes \\ %{}) do
    @john_doe_user_params
    |> Map.merge(changes)
    |> register_user()
  end
end
