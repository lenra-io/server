defmodule Lenra.AppUserSessionService do
  @moduledoc """
    The service that manages the client's applications measurements.
  """
  alias Lenra.{AppUserSession, LenraApplicationServices, Repo}
  require Logger

  def get_by(clauses) do
    Repo.get_by(AppUserSession, clauses)
  end

  def create(user_id, params) do
    case LenraApplicationServices.fetch_by(%{service_name: params.service_name}) do
      {:ok, app} ->
        Repo.insert(AppUserSession.new(Enum.into(params, %{user_id: user_id, application_id: app.id})))

      {:error, error} ->
        {:error, error}
    end
  end
end
