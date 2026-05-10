defmodule BackendWeb.Router do
  @moduledoc false
  use BackendWeb, :router

  pipeline :api do
    plug CORSPlug, origin: "*"
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug BackendWeb.Plugs.RequireAuth
  end

  scope "/api", BackendWeb do
    pipe_through :api

    options "/*path", AuthController, :options
    post "/auth/signup", AuthController, :signup
    post "/auth/signin", AuthController, :signin

    pipe_through :authenticated

    post "/auth/signout", AuthController, :signout
    get "/auth/me", AuthController, :me
    get "/todos", TodoController, :index
    post "/todos", TodoController, :create
    patch "/todos/:todo_id", TodoController, :update
    delete "/todos/:todo_id", TodoController, :delete
  end

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/", BackendWeb do
    pipe_through :browser
    get "/", Controller, :spa
  end
end
