defmodule LenraWeb.ControllerHelpers do
  @moduledoc """
    LenraWeb.ControllerHelpers give some helper functions to assign error/data to the conn and send the response to the view.
  """

  def assign_error(%Plug.Conn{} = conn, error) do
    error
    |> case do
      %Ecto.Changeset{valid?: false} ->
        conn
        |> Plug.Conn.put_status(400)
        |> add_error(error)

      %Lenra.Errors.TechnicalError{reason: :error_404} ->
        conn
        |> Plug.Conn.put_status(404)
        |> add_error(error)

      :error_500 ->
        conn
        |> Plug.Conn.put_status(500)
        |> add_error(Lenra.Errors.error_500())

      :forbidden ->
        conn
        |> Plug.Conn.put_status(403)
        |> add_error(Lenra.Errors.forbidden())

      %Lenra.Errors.BusinessError{} ->
        conn
        |> Plug.Conn.put_status(400)
        |> add_error(error)

      %Lenra.Errors.TechnicalError{} ->
        conn
        |> Plug.Conn.put_status(400)
        |> add_error(error)

      %Lenra.Errors.DevError{} ->
        conn
        |> Plug.Conn.put_status(400)
        |> add_error(error)

      _error ->
        conn
        |> Plug.Conn.put_status(400)
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
