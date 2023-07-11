defmodule LenraWeb.Plug.VerifyCgu do
  @moduledoc """
  Plug that checks whether the latest cgu has been accepted or not
  """
  use LenraWeb, :controller

  alias Lenra.Errors.BusinessError

  def init(opts), do: opts

  def call(conn, _opts) do
    user = LenraWeb.Auth.current_resource(conn)

    if Lenra.Legal.user_accepted_latest_cgu?(user.id) do
      conn
    else
      conn
      |> put_view(LenraCommonWeb.BaseView)
      |> assign_error(BusinessError.did_not_accept_cgu())
      |> reply()
    end
  end
end
