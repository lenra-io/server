defmodule LenraWeb.Auth do
  @token_key :oauth_token
  @resource_key :oauth_resource

  def put_token(conn, token) do
    Plug.Conn.put_private(conn, @token_key, token)
  end

  def put_resource(conn, resource) do
    Plug.Conn.put_private(conn, @resource_key, resource)
  end

  def current_token(conn) do
    conn.private[@token_key]
  end

  def current_resource(conn) do
    conn.private[@resource_key]
  end
end
