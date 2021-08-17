defmodule Lenra.OpenfaasRunActionMeasurementServices do
  @moduledoc """
    The service that manages the openfaas measurements.
  """
  require Logger

  alias Lenra.{Repo, OpenfaasRunActionMeasurement}

  def get(id) do
    Repo.get(OpenfaasRunActionMeasurement, id)
  end

  def get_by(clauses) do
    Repo.get_by(OpenfaasRunActionMeasurement, clauses)
  end

  def create(params) do
    Repo.insert(OpenfaasRunActionMeasurement.new(params))
  end
end
