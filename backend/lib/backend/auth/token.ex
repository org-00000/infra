defmodule Backend.Auth.Token do
  @moduledoc false
  @salt "user auth"

  def sign(user_id) do
    Phoenix.Token.sign(BackendWeb.Endpoint, @salt, user_id)
  end

  def verify(token) do
    Phoenix.Token.verify(BackendWeb.Endpoint, @salt, token, max_age: 86_400 * 30)
  end
end
