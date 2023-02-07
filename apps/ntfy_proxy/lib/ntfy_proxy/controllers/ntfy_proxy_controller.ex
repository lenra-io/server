defmodule NtfyProxy.NtfyProxyController do
  use NtfyProxy, :controller
  import Plug.Conn

  require Logger

  def auth(conn, params) do
    Logger.info(inspect(params))
    Logger.info(inspect(conn.req_headers))
    dispatch(conn)
  end

  def push(conn, _params) do
    dispatch(conn)
  end

  def json(conn, _params) do
    dispatch_stream(conn, true)
  end

  def client(conn, long_polling? \\ false) do
    conn.method
    |> String.downcase()
    |> String.to_existing_atom()
    |> :hackney.request(
      uri(conn),
      conn.req_headers,
      :stream,
      connect_timeout: req_timeout(long_polling?),
      recv_timeout: req_timeout(long_polling?),
      ssl_options: [],
      max_redirect: 5
    )
  end

  def dispatch_stream(%Plug.Conn{} = conn, long_polling? \\ false) do
    {:ok, client} = client(conn, long_polling?)

    conn
    |> write_proxy(client)
    |> stream_proxy(client)
  end

  def dispatch(%Plug.Conn{} = conn) do
    {:ok, status, _headers, client} =
      conn.method
      |> String.downcase()
      |> String.to_existing_atom()
      |> :hackney.request(
        uri(conn),
        conn.req_headers,
        conn.private[:raw_body]
      )

    {:ok, body} = :hackney.body(client)
    send_resp(conn, status, body)
  end

  def write_proxy(conn, client) do
    Logger.debug("Dispatching body : #{conn.private[:raw_body]}.")
    :hackney.send_body(client, conn.private[:raw_body])
    conn
  end

  def read_proxy(conn, client) do
    Logger.debug("Starting response now.")

    case :hackney.start_response(client) do
      {:ok, status, headers, _client} ->
        Logger.debug("Proxy response :ok. Status : #{status}")
        {:ok, res_body} = :hackney.body(client)
        send_resp(%{conn | resp_headers: headers}, status, res_body)

      {:ok, _client_ref} ->
        Logger.debug("Got a client ref message ?")
        send_resp(conn, 200, "")

      {:error, message} ->
        Logger.debug("Timeout")
        send_resp(conn, 408, Atom.to_string(message))
    end
  end

  def stream_proxy(conn, client) do
    case :hackney.start_response(client) do
      {:ok, status, headers, _client} ->
        Logger.debug("Proxy response :ok. Status : #{status} ; #{inspect(headers)}")

        %{conn | resp_headers: headers}
        |> IO.inspect()
        |> send_chunked(status)
        |> stream_resp(client)

      {:error, message} ->
        send_resp(conn, 408, Atom.to_string(message))
    end
  end

  def stream_resp(conn, client) do
    case :hackney.stream_body(client) do
      {:ok, part} ->
        Logger.debug("New chunk sent : #{part}")
        chunk(conn, part)
        stream_resp(conn, client)

      :done ->
        conn
    end
  end

  def uri(conn) do
    "#{proxy()}#{conn.request_path}?#{conn.query_string}"
  end

  def proxy() do
    "localhost:8001"
  end

  def req_timeout(long_polling? \\ false) do
    if long_polling? do
      :infinity
    else
      5000
    end
  end
end
