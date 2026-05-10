defmodule BackendWeb.AuthController do
  @moduledoc false
  use BackendWeb, :controller
  alias Backend.{Accounts, Auth.Token}

  def options(conn, _), do: send_resp(conn, 204, "")

  def signup(conn, params) do
    case Accounts.create_user(params) do
      {:ok, user} ->
        conn |> put_status(201) |> json(%{token: Token.sign(user.id), user: %{email: user.email}})

      {:error, cs} ->
        if email_taken?(cs) do
          conn |> put_status(409) |> json(%{error: "Email already registered"})
        else
          conn |> put_status(422) |> json(%{error: error_message(cs)})
        end
    end
  end

  def signin(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate(email, password) do
      {:ok, user} -> json(conn, %{token: Token.sign(user.id), user: %{email: user.email}})
      {:error, _} -> conn |> put_status(401) |> json(%{error: "Invalid credentials"})
    end
  end

  def signout(conn, _), do: send_resp(conn, 204, "")

  def me(conn, _) do
    json(conn, %{email: conn.assigns.current_user.email})
  end

  defp email_taken?(cs) do
    Enum.any?(cs.errors, fn
      {:email, {_, opts}} -> opts[:constraint] == :unique
      _ -> false
    end)
  end

  defp error_message(cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, _} -> msg end)
    |> Enum.map_join("; ", fn {k, v} -> "#{k}: #{Enum.join(v, ", ")}" end)
  end
end
