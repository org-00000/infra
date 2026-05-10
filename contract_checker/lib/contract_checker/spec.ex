defmodule ContractChecker.Spec do
  @moduledoc """
  [[id:a1b2c3d4-e5f6-7890-abcd-ef1234567890]]
  [[ref:a1b2c3d4-e5f6-7890-abcd-ef1234567890][Specification]]
  Loads and caches the OpenAPI spec from $FRONTEND_OPENAPI at startup.
  """

  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def get, do: GenServer.call(__MODULE__, :get)

  @impl GenServer
  def init(_opts) do
    {:ok, load()}
  end

  @impl GenServer
  def handle_call(:get, _from, spec), do: {:reply, spec, spec}

  defp load do
    path =
      System.get_env("FRONTEND_OPENAPI") ||
        raise "FRONTEND_OPENAPI is not set"

    path
    |> YamlElixir.read_from_file!()
    |> OpenApiSpex.OpenApi.Decode.decode()
  end
end
