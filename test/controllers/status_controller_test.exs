defmodule SwarmBrain.StatusControllerTest do
  use SwarmBrain.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/status"
    assert text_response(conn, 200) == "OK"
  end
end
