defmodule ContractCheckerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :contract_checker

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  plug ContractCheckerWeb.ProxyPlug
end
