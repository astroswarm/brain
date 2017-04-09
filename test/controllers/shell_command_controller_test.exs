defmodule SwarmBrain.ShellCommandControllerTest do
  use SwarmBrain.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "executes command with arguments and returns output", %{conn: conn} do
    conn = post(
      conn,
      shell_command_path(conn, :create),
      %{"command" => "echo", "args" => ["hi there!"]}
    )
    assert json_response(conn, 200)["output"] == "hi there!\n"
    assert json_response(conn, 200)["exit_code"] == 0
  end

  test "executes command without arguments and returns output", %{conn: conn} do
    conn = post(
      conn,
      shell_command_path(conn, :create),
      %{"command" => "false"}
    )
    assert json_response(conn, 200)["output"] == ""
    assert json_response(conn, 200)["exit_code"] == 1
  end
end
