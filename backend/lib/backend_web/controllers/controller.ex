defmodule BackendWeb.Controller do
  @moduledoc false
  use BackendWeb, :controller

  def spa(conn, _) do
    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, Application.app_dir(:backend, "priv/static/index.html"))
  end
end
