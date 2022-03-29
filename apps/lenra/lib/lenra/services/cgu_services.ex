defmodule Lenra.CguService do
  @moduledoc """
    The service that get the latest CGU.
  """
  alias Lenra.{Cgu, Repo}

  def get_latest_cgu do
    cgu = Cgu |> Ecto.Query.last(:inserted_at) |> Repo.one()

    case cgu do
      nil -> {:error, :error_404}
      cgu -> {:ok, cgu}
    end
  end

  @doc """
    Compares two CGU versions.

    Returns a tuple with the following values:
    - {:ok, 0}, if the versions are equal
    - {:ok, -1} if the first version is older than the second
    - {:ok, 1} if the first version is newer than the second
    - {:error, error} if an error occurred
  """
  def compare_versions(cgu1, cgu2) do
    cond do
      cgu1.inserted_at == cgu2.inserted_at ->
        {:ok, 0}

      cgu1.inserted_at < cgu2.inserted_at ->
        {:ok, -1}

      cgu1.inserted_at > cgu2.inserted_at ->
        {:ok, 1}

      true ->
        {:error, "Cannot compare versions"}
    end
  end

  @doc """
    Returns the latest CGU from a list.

    Returns a tuple with the following values:
    - {:ok, cgu}, with cgu being the latest CGU
    - {:error, error} if an error occurred
  """
  def get_latest_cgu_from_list(list) do
    cond do
      Enum.count(list) == 0 ->
        {:error, "Cannot get latest CGU from an empty list"}

      Enum.count(list) == 1 ->
        {:ok, Enum.at(list, 0)}

      true ->
        latest_cgu = Enum.at(list, 0)
        Enum.each(list, fn cgu ->
          with {:ok, 1} <- compare_versions(cgu, latest_cgu) do
            ^latest_cgu = cgu
          end
        end)
        {:ok, latest_cgu}
    end
  end
end
