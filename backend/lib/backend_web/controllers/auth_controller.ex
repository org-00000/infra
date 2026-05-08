defmodule BackendWeb.AuthController do
  use BackendWeb, :controller
  alias Backend.{Accounts, Auth.Token}

  def options(conn, _params) do
    send_resp(conn, 204, "")
  end

  def signup(conn, params) do
    case Accounts.create_user(params) do
      {:ok, user} ->
        token = Token.sign(user.id)
        conn |> put_status(201) |> json(%{token: token, user: %{email: user.email}})

      {:error, changeset} ->
        if email_taken?(changeset) do
          conn |> put_status(409) |> json(%{error: "Email already registered"})
        else
          conn |> put_status(422) |> json(%{error: error_message(changeset)})
        end
    end
  end

  def signin(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate(email, password) do
      {:ok, user} ->
        token = Token.sign(user.id)
        conn |> json(%{token: token, user: %{email: user.email}})

      {:error, _} ->
        conn |> put_status(401) |> json(%{error: "Invalid credentials"})
    end
  end

  def signout(conn, _params),
      do: conn |> send_resp(204, "")

  def me(conn, _params) do
    user = conn.assigns.current_user
    conn |> json(%{email: user.email})
  end

  defp email_taken?(changeset) do
    Enum.any?(changeset.errors, fn
      {:email, {_msg, opts}} -> opts[:constraint] == :unique
      _ -> false
    end)
  end

  defp error_message(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
    |> Enum.map_join("; ", fn {k, v} -> "#{k}: #{Enum.join(v, ", ")}" end)
  end
end
