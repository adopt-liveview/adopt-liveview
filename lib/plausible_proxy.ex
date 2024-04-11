defmodule PlausibleProxy do
  @moduledoc """
  Based on: https://github.com/DockYard/plausible_proxy/blob/main/lib/plausible_proxy/plug.ex
  Vendored to make work on our Elixir version

  A plug to intercept:
    * GET calls for the plausible script
    * POST calls to `/api/event`

  Options:
    * `local_path` is the local server path to serve up plausible js file from
      * Defaults to `"/js/plausible_script.js"`
    * `script_extension` is the specific script to download from plausible.
      * See: https://plausible.io/docs/script-extensions#all-our-script-extensions
      * Defaults to `"script.js"`
    * `remote_ip_headers` is a list of headers to search for inbound remote ip
      * First value found will populate the `X-Forwarded-For` header on requests to Plausible
      * If none are found in request, `PlausibleProxy` will use `conn.remote_ip`
      * Defaults to `["fly-client-ip", "x-real-ip"]`


  Event Callback Function:
    * 3 arity function that receives `conn`, `payload`, and `remote_ip`
    * Returns `{:ok, payload_modifiers}` where `payload_modifiers` is a Map of key/value pairs to modify the event payload sent to Plausible

  Supported payload_modifiers:
    * `props` is a map of values to pass in the "props" value of the event payload body sent to Plausible
      * e.g. `%{props: %{"company" => "DockYard"}}`

  ## Example

      defmodule MyApp.Endpoint do
        ...

        plug PlausibleProxy.Plug,
          remote_ip_headers: ["x-myhosting-remote-ip"],
          script_extension: "script.pageview-props.js"

        ...
      end

  """
  @behaviour Plug

  require Logger
  import Plug.Conn

  @default_local_path "/js/plausible_script.js"
  @default_script_extension "script.pageview-props.js"
  @default_remote_ip_headers ["fly-client-ip", "x-real-ip"]

  @impl Plug
  def init(opts) do
    %{
      local_path: Keyword.get(opts, :local_path, @default_local_path),
      script_extension: Keyword.get(opts, :script_extension, @default_script_extension),
      remote_ip_headers: Keyword.get(opts, :remote_ip_headers, @default_remote_ip_headers)
    }
  end

  defp script(%{script_extension: ext}), do: "https://plausible.io/js/#{ext}"

  @impl Plug
  def call(%{request_path: path} = conn, %{local_path: path} = opts) do
    remote_ip_address = determine_ip_address(conn, opts)
    headers = build_headers(conn, remote_ip_address)

    case HTTPoison.get(script(opts), headers) do
      {:ok, resp} ->
        conn
        |> send_resp(resp.status_code, resp.body)
        |> halt()

      {:error, error} ->
        Logger.error("plausible_proxy failed to get script, got: #{Exception.message(error)}")
        conn
    end
  end

  def call(%Plug.Conn{request_path: "/api/event"} = conn, opts) do
    with {:ok, body, conn} <- read_body(conn),
         {:ok, payload} <- Jason.decode(body),
         remote_ip_address = determine_ip_address(conn, opts),
         {:ok, resp} <- post_event(conn, payload, remote_ip_address, %{}) do
      headers =
        resp.headers
        |> Enum.filter(fn
          {"Content-Length", _} -> false
          _ -> true
        end)

      conn
      |> prepend_resp_headers(headers)
      |> send_resp(resp.status_code, resp.body)
      |> halt()
    else
      error ->
        Logger.error("plausible_proxy failed to POST /api/event, got: #{inspect(error)}")

        conn
        |> send_resp(500, "plausible_proxy failed to POST /api/event")
        |> halt()
    end
  end

  @impl Plug
  def call(conn, _) do
    conn
  end

  defp build_headers(conn, ip_address, optional_headers \\ []) do
    user_agent = get_one_header(conn, "user-agent")

    [
      {"X-Forwarded-For", ip_address},
      {"User-Agent", user_agent}
      | optional_headers
    ]
  end

  defp get_one_header(conn, header_key) do
    conn
    |> Plug.Conn.get_req_header(header_key)
    |> List.first()
  end

  defp determine_ip_address(conn, %{remote_ip_headers: remote_ip_headers}) do
    Enum.find_value(remote_ip_headers, &get_one_header(conn, &1)) ||
      List.to_string(:inet.ntoa(conn.remote_ip))
  end

  defp post_event(conn, payload, remote_ip_address, payload_modifiers) do
    headers = build_headers(conn, remote_ip_address, [{"Content-Type", "application/json"}])

    body = %{
      "name" => payload["n"],
      "url" => payload["u"],
      "domain" => payload["d"],
      "referrer" => payload["r"],
      "props" => payload["p"]
    }

    body =
      case payload_modifiers do
        %{props: props} -> Map.put(body, "props", props)
        _ -> body
      end

    with {:ok, body} <- Jason.encode(body),
         {:ok, resp} <- HTTPoison.post("https://plausible.io/api/event", body, headers) do
      {:ok, resp}
    else
      {:error, error} ->
        Logger.error(
          "plausible_proxy failed to POST /api/event, got: #{Exception.message(error)}"
        )

        {:error, error}
    end
  end
end
