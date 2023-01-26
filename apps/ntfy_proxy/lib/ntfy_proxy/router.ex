defmodule NtfyProxy.Router do
  use NtfyProxy, :router
  alias NtfyProxy.NtfyProxyController

  # scope "/" do
  #   # get("/:topic/auth", NtfyProxyController, :auth)
  #   # put("/:topic", NtfyProxyController, :push)
  # end

  get("/:topic/json", NtfyProxyController, :json)
  post("/:topic", NtfyProxyController, :push)
end
