defmodule LenraWeb.Auth do
  @moduledoc """
    This module contains the Auth API for Lenra Web.
    Put/Get the current resource (user) in the conn
    Put/Get the current token in the conn
    Put/Get the current token introspect (response from Hydra) in the conn
  """
  @token_key :oauth_token
  @token_key_introspect :oauth_token_introspect
  @resource_key :oauth_resource

  def put_token(conn, token) do
    Plug.Conn.put_private(conn, @token_key, token)
  end

  def put_token_introspect(conn, response_body) do
    Plug.Conn.put_private(conn, @token_key_introspect, response_body)
  end

  def put_resource(conn, resource) do
    Plug.Conn.put_private(conn, @resource_key, resource)
  end

  def current_token(conn) do
    conn.private[@token_key]
  end

  def current_token_introspect(conn) do
    conn.private[@token_key_introspect]
  end

  def current_resource(conn) do
    conn.private[@resource_key]
  end
end
