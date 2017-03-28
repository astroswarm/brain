defmodule SwarmBrain.PageController do
  use SwarmBrain.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
