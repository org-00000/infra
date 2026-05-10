defmodule ContractCheckerWeb.ProxyPlug do
  @moduledoc """
  [[id:c3d4e5f6-a7b8-9012-cdef-123456789012]]
  [[ref:c3d4e5f6-a7b8-9012-cdef-123456789012][Specification]]
  Validates each request against the OpenAPI spec, proxies to $BACKEND_URL,
  then validates the response status. Invalid requests return 400; unexpected
  response statuses are logged but passed through.
  """

  import Plug.Conn
  require Logger

  alias ContractChecker.{Spec, Validator}

  def init(opts), do: opts

  def call(conn, _opts) do
    spec = Spec.get()
    conn = fetch_body(conn)

    case Validator.validate_request(spec, conn) do
      {:ok, operation} ->
        proxy(conn, spec, operation)

      :not_covered ->
        proxy(conn, spec, nil)

      {:error, errors} ->
        msg = Enum.join(errors, "; ")
        Logger.warning("CONTRACT request violation #{conn.method} #{conn.request_path}: #{msg}")

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: "Contract violation: #{msg}"}))
        |> halt()
    end
  end

  defp fetch_body(conn) do
    case conn.body_params do
      %Plug.Conn.Unfetched{} ->
        Plug.Parsers.call(
          conn,
          Plug.Parsers.init(parsers: [:json], json_decoder: Jason, pass: ["*/*"])
        )

      _ ->
        conn
    end
  end

  defp proxy(conn, spec, operation) do
    backend_url = Application.get_env(:contract_checker, :backend_url, "http://localhost:4000")
    url = backend_url <> conn.request_path <> query_string(conn)

    result =
      Req.request(
        method: conn.method |> String.downcase() |> String.to_atom(),
        url: url,
        headers: forward_headers(conn),
        body: encode_body(conn),
        redirect: false,
        retry: false,
        decode_body: false
      )

    case result do
      {:ok, resp} ->
        if operation do
          case Validator.validate_response(spec, operation, resp.status) do
            :ok ->
              :ok

            {:error, errors} ->
              Logger.warning(
                "CONTRACT response violation #{conn.method} #{conn.request_path}: #{Enum.join(errors, "; ")}"
              )
          end
        end

        conn
        |> copy_response_headers(resp)
        |> send_resp(resp.status, resp.body || "")

      {:error, reason} ->
        Logger.error("Proxy error #{conn.method} #{conn.request_path}: #{inspect(reason)}")

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(502, Jason.encode!(%{error: "Backend unreachable"}))
    end
  end

  defp query_string(%{query_string: ""}), do: ""
  defp query_string(%{query_string: qs}), do: "?" <> qs

  defp forward_headers(conn) do
    Enum.reject(conn.req_headers, fn {k, _} -> k in ~w(host transfer-encoding content-length) end)
  end

  defp encode_body(conn) do
    case conn.body_params do
      params when map_size(params) > 0 -> Jason.encode!(params)
      _ -> ""
    end
  end

  defp copy_response_headers(conn, resp) do
    Enum.reduce(resp.headers, conn, fn {k, v}, acc ->
      if k in ~w(transfer-encoding content-encoding) do
        acc
      else
        put_resp_header(acc, k, List.wrap(v) |> Enum.join(", "))
      end
    end)
  end
end
