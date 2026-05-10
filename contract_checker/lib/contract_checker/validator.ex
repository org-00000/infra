defmodule ContractChecker.Validator do
  @moduledoc """
  [[id:b2c3d4e5-f6a7-8901-bcde-f12345678901]]
  [[ref:b2c3d4e5-f6a7-8901-bcde-f12345678901][Specification]]
  Validates HTTP requests and responses against an OpenApiSpex spec.
  """

  alias OpenApiSpex.{OpenApi, Operation}

  def validate_request(%OpenApi{} = spec, conn) do
    case find_operation(spec, conn.method, conn.request_path) do
      nil ->
        :not_covered

      {operation, _path_params} ->
        case validate_body(spec, operation, conn) do
          [] -> {:ok, operation}
          errors -> {:error, errors}
        end
    end
  end

  def validate_response(%OpenApi{} = _spec, %Operation{} = operation, status) do
    declared = operation.responses |> Map.keys() |> Enum.map(&to_string/1)

    if to_string(status) in declared or "default" in declared do
      :ok
    else
      {:error, ["Response status #{status} not declared; expected one of #{inspect(declared)}"]}
    end
  end

  defp find_operation(%OpenApi{paths: paths}, method, request_path) do
    Enum.find_value(paths, fn {template, path_item} ->
      case match_path(template, request_path) do
        {:ok, path_params} ->
          op = operation_for_method(path_item, method)
          if op, do: {op, path_params}

        :error ->
          nil
      end
    end)
  end

  defp match_path(template, path) do
    pattern = "^" <> String.replace(template, ~r/\{[^}]+\}/, "([^/]+)") <> "$"

    case Regex.run(Regex.compile!(pattern), path) do
      nil -> :error
      [_ | captures] -> {:ok, captures}
    end
  end

  defp operation_for_method(path_item, method) do
    case String.downcase(method) do
      "get" -> path_item.get
      "post" -> path_item.post
      "put" -> path_item.put
      "patch" -> path_item.patch
      "delete" -> path_item.delete
      "options" -> path_item.options
      _ -> nil
    end
  end

  defp validate_body(%OpenApi{} = spec, %Operation{} = operation, conn) do
    with true <- conn.method in ["POST", "PUT", "PATCH"],
         %{required: true} = request_body <- operation.requestBody,
         %OpenApiSpex.MediaType{schema: schema} <-
           Map.get(request_body.content, "application/json"),
         {:ok, body} <- fetch_body(conn) do
      case OpenApiSpex.cast_value(body, schema, spec) do
        {:ok, _} -> []
        {:error, errors} -> Enum.map(errors, &to_string/1)
      end
    else
      false -> []
      nil -> []
      {:error, reason} -> ["Could not parse request body: #{reason}"]
    end
  end

  defp fetch_body(conn) do
    case conn.body_params do
      %Plug.Conn.Unfetched{} -> {:error, "body not fetched"}
      params -> {:ok, params}
    end
  end
end
