defmodule ContractCheckerWeb.Router do
  @moduledoc "Routes all requests through ProxyPlug."
  use ContractCheckerWeb, :router

  pipeline :proxy do
    plug :accepts, ["json"]
    plug ContractCheckerWeb.ProxyPlug
  end

  scope "/" do
    pipe_through :proxy
  end
end
