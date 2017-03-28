defmodule SwarmBrain.StatusController do
  use SwarmBrain.Web, :controller

  def index(conn, _params) do
    text(conn, "OK")
  end
end
