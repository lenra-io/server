defmodule LenraWeb.ControllerHelpers do
  @moduledoc """
    LenraWeb.ControllerHelpers give some helper functions to assign error/data to the conn and send the response to the view.
  """

  def assign_error(%Plug.Conn{} = conn, error) do
    error
    |> case do
      %Ecto.Changeset{valid?: false} ->
        Plug.Conn.put_status(conn, 400)
        |> add_error(error)

      :error_404 ->
        Plug.Conn.put_status(conn, 404)
        |> add_error(Lenra.Errors.error_404())

      :error_500 ->
        Plug.Conn.put_status(conn, 500)
        |> add_error(Lenra.Errors.error_500())

      :forbidden ->
        Plug.Conn.put_status(conn, 403)
        |> add_error(Lenra.Errors.forbidden())

      %Lenra.Errors.BusinessError{} ->
        Plug.Conn.put_status(conn, 400)
        |> add_error(error)

      %Lenra.Errors.TechnicalError{} ->
        Plug.Conn.put_status(conn, 400)
        |> add_error(error)

      %Lenra.Errors.DevError{} ->
        Plug.Conn.put_status(conn, 400)
        |> add_error(error)

      _error ->
        Plug.Conn.put_status(conn, 400)
        |> add_error(Lenra.Errors.bad_request())
    end
  end

  def add_error(%Plug.Conn{} = conn, error) do
    Plug.Conn.assign(conn, :error, error)
  end

  def assign_data(%Plug.Conn{} = conn, value) do
    Plug.Conn.assign(conn, :data, value)
  end

  def assign_data(%Plug.Conn{} = conn, key, value) do
    conn =
      if Map.has_key?(conn.assigns, :data) do
        conn
      else
        Plug.Conn.assign(conn, :data, %{})
      end

    %{conn | assigns: put_in(conn.assigns, [:data, key], value)}
  end

  def reply(%Plug.Conn{assigns: %{error: _}} = conn) do
    Phoenix.Controller.render(conn, "error.json")
  end

  def reply(%Plug.Conn{} = conn) do
    Phoenix.Controller.render(conn, "success.json")
  end
end
