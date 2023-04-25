defmodule IdentityWeb.PageController do
  use IdentityWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
