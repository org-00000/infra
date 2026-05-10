defmodule Backend.Todos do
  @moduledoc false
  import Ecto.Query
  alias Backend.{Repo, Todos.Todo}

  def list_todos(user_id) do
    Repo.all(from t in Todo, where: t.user_id == ^user_id, order_by: [desc: t.inserted_at])
  end

  def create_todo(user_id, attrs) do
    %Todo{user_id: user_id} |> Todo.changeset(attrs) |> Repo.insert()
  end

  def update_todo(user_id, id, attrs) do
    case Repo.get_by(Todo, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      todo -> todo |> Todo.changeset(attrs) |> Repo.update()
    end
  end

  def delete_todo(user_id, id) do
    case Repo.get_by(Todo, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      todo -> Repo.delete(todo)
    end
  end
end
