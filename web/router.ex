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

    # With great power comes great irresponsibility. Remove this prior to public
    # release. Leaving as is until then for more rapid feature development.
    # Once use cases are known, move this to a private library and generate
    # endpoints to invoke specific features.
    post "/execute_command", ShellCommandController, :create
  end
end
