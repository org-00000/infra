defmodule BackendWeb.TodoController do
  @moduledoc false
  use BackendWeb, :controller
  alias Backend.Todos

  def index(conn, _) do
    json(conn, Enum.map(Todos.list_todos(conn.assigns.current_user.id), &serialize/1))
  end

  def create(conn, params) do
    case Todos.create_todo(conn.assigns.current_user.id, params) do
      {:ok, todo} -> conn |> put_status(201) |> json(serialize(todo))
      {:error, _} -> conn |> put_status(422) |> json(%{error: "Validation failed"})
    end
  end

  def update(conn, %{"todo_id" => id} = params) do
    case Todos.update_todo(conn.assigns.current_user.id, id, params) do
      {:ok, todo} -> json(conn, serialize(todo))
      {:error, :not_found} -> conn |> put_status(404) |> json(%{error: "Not found"})
      {:error, _} -> conn |> put_status(422) |> json(%{error: "Validation failed"})
    end
  end

  def delete(conn, %{"todo_id" => id}) do
    case Todos.delete_todo(conn.assigns.current_user.id, id) do
      {:ok, _} -> send_resp(conn, 204, "")
      {:error, :not_found} -> conn |> put_status(404) |> json(%{error: "Not found"})
    end
  end

  defp serialize(t),
    do: %{
      id: t.id,
      text: t.text,
      completed: t.completed,
      createdAt: t.inserted_at |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_iso8601()
    }
end
