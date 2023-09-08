defmodule ApplicationRunner.Contract.EnvironmentTest do
  @moduledoc false

  use ApplicationRunner.RepoCase

  alias ApplicationRunner.Contract.Environment
  alias ApplicationRunner.Repo

  test "get on embeded schema should return same environment" do
    env =
      Environment.new()
      |> Repo.insert!()

    embed_env = Repo.get!(Environment, env.id)

    assert env.id == embed_env.id
  end

  test "embed schema with valid env should return env" do
    env =
      Environment.new()
      |> Repo.insert!()
      |> Environment.embed()

    assert is_struct(env, Environment)
  end

  test "embed schema with invalid env should return error" do
    env =
      %{truc: "test"}
      |> Environment.embed()

    assert is_struct(env, Ecto.Changeset)
    assert not env.valid?
  end
end
