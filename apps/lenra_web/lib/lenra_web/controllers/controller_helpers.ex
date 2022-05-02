defmodule LenraWeb.ControllerHelpers do
  @moduledoc """
    LenraWeb.ControllerHelpers give some helper functions to assign error/data to the conn and send the response to the view.
  """

  def assign_error(%Plug.Conn{} = conn, error) do
    error
    |> case do
      %Ecto.Changeset{valid?: false} ->
        Plug.Conn.put_status(conn, 400)

      :error_404 ->
        Plug.Conn.put_status(conn, 404)

      :error_500 ->
        Plug.Conn.put_status(conn, 500)

      :forbidden ->
        Plug.Conn.put_status(conn, 403)

      _error ->
        Plug.Conn.put_status(conn, 400)
    end
    |> add_error(error)
  end

  def add_error(%Plug.Conn{} = conn, error) do
    error_list = Map.get(conn.assigns, :errors, [])
    Plug.Conn.assign(conn, :errors, [error | error_list])
  end

  def assign_data(%Plug.Conn{} = conn, key, value) do
    data_map = Map.get(conn.assigns, :data, %{})
    Plug.Conn.assign(conn, :data, Map.put(data_map, key, value))
  end

  def assign_all(%Plug.Conn{} = conn, value) do
    Plug.Conn.assign(conn, :data, value)
  end

  def reply(%Plug.Conn{assigns: %{errors: _}} = conn) do
    Phoenix.Controller.render(conn, "error.json")
  end

  def reply(%Plug.Conn{} = conn) do
    Phoenix.Controller.render(conn, "success.json")
  end
end
