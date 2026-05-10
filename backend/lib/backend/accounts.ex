defmodule Backend.Accounts do
  @moduledoc false
  import Ecto.Query
  alias Backend.{Repo, Accounts.User}

  def create_user(attrs) do
    %User{} |> User.changeset(attrs) |> Repo.insert()
  end

  def authenticate(email, password) do
    user = Repo.one(from u in User, where: u.email == ^email)

    if user && Bcrypt.verify_pass(password, user.password_hash) do
      {:ok, user}
    else
      Bcrypt.no_user_verify()
      {:error, :invalid}
    end
  end

  def get_user(id), do: Repo.get(User, id)
end
