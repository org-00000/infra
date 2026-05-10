defmodule ContractChecker.ValidatorTest do
  @moduledoc """
  Message sequences against the OpenAPI spec. Passing sequences must return
  {:ok, _}; failing sequences must return {:error, _}.
  """

  use ExUnit.Case, async: true
  alias ContractChecker.Validator

  setup_all do
    path =
      System.get_env("FRONTEND_OPENAPI") ||
        Path.expand("../../../frontend/openapi.yaml", __DIR__)

    spec =
      path
      |> YamlElixir.read_from_file!()
      |> OpenApiSpex.OpenApi.Decode.decode()

    %{spec: spec}
  end

  describe "passing sequences" do
    test "POST /auth/signup with valid body", %{spec: spec} do
      assert {:ok, _} =
               Validator.validate_request(spec, conn("POST", "/auth/signup", %{"email" => "a@b.com", "password" => "secret"}))
    end

    test "POST /auth/signin with valid body", %{spec: spec} do
      assert {:ok, _} =
               Validator.validate_request(spec, conn("POST", "/auth/signin", %{"email" => "a@b.com", "password" => "secret"}))
    end

    test "GET /todos (no body)", %{spec: spec} do
      assert {:ok, _} = Validator.validate_request(spec, conn("GET", "/todos", nil))
    end

    test "POST /todos with valid body", %{spec: spec} do
      assert {:ok, _} =
               Validator.validate_request(spec, conn("POST", "/todos", %{"text" => "buy milk"}))
    end

    test "PATCH /todos/{todoId} with valid body", %{spec: spec} do
      assert {:ok, _} =
               Validator.validate_request(spec, conn("PATCH", "/todos/some-uuid", %{"completed" => true}))
    end

    test "DELETE /todos/{todoId} (no body)", %{spec: spec} do
      assert {:ok, _} = Validator.validate_request(spec, conn("DELETE", "/todos/some-uuid", nil))
    end
  end

  describe "failing sequences" do
    test "unknown path is rejected", %{spec: spec} do
      assert {:error, [msg]} = Validator.validate_request(spec, conn("GET", "/unknown", nil))
      assert msg =~ "No operation matches"
    end

    test "wrong method on known path is rejected", %{spec: spec} do
      assert {:error, _} = Validator.validate_request(spec, conn("DELETE", "/auth/signup", nil))
    end

    test "POST /auth/signup missing required email", %{spec: spec} do
      assert {:error, _} =
               Validator.validate_request(spec, conn("POST", "/auth/signup", %{"password" => "x"}))
    end

    test "POST /todos missing required text", %{spec: spec} do
      assert {:error, _} = Validator.validate_request(spec, conn("POST", "/todos", %{}))
    end
  end

  describe "response validation" do
    test "declared status is accepted", %{spec: spec} do
      {:ok, op} = Validator.validate_request(spec, conn("POST", "/auth/signup", %{"email" => "x@y.com", "password" => "123456"}))
      assert :ok = Validator.validate_response(spec, op, 201)
    end

    test "undeclared status is rejected", %{spec: spec} do
      {:ok, op} = Validator.validate_request(spec, conn("POST", "/auth/signup", %{"email" => "x@y.com", "password" => "123456"}))
      assert {:error, _} = Validator.validate_response(spec, op, 500)
    end
  end

  defp conn(method, path, nil), do: Plug.Test.conn(method, path)
  defp conn(method, path, params), do: %{Plug.Test.conn(method, path) | body_params: params}
end
