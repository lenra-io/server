defmodule ApplicationRunner.Quantum do
  @moduledoc """
    The quantum schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:last_execution_date]}
  schema "quantum" do
    field(:last_execution_date, :naive_datetime)
  end

  def changeset(quantum, params \\ %{}) do
    quantum
    |> cast(params, [:last_execution_date])
    |> validate_required([:last_execution_date])
  end

  def update(last_execution_date) do
    %__MODULE__{id: 1}
    |> __MODULE__.changeset(%{"last_execution_date" => last_execution_date})
  end

  def new(last_execution_date) do
    %__MODULE__{id: 1}
    |> __MODULE__.changeset(%{"last_execution_date" => last_execution_date})
  end
end
