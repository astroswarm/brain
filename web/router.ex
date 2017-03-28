defmodule SwarmBrain.Router do
  use SwarmBrain.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SwarmBrain do
    pipe_through :browser # Use the default browser stack

    get "/status", StatusController, :index
    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", SwarmBrain do
    pipe_through :api

    post "/execute_command", ShellCommandController, :create
  end
end
