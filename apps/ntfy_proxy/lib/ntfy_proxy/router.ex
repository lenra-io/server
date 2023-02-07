defmodule NtfyProxy.Router do
  use NtfyProxy, :router
  alias NtfyProxy.NtfyProxyController

  get("/:topic/json", NtfyProxyController, :json)
end
