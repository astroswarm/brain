defmodule SwarmBrain.ShellCommandController do
  use SwarmBrain.Web, :controller

  def create(conn, %{"command" => command, "args" => args}) do
    output = execute(command, args)
    json(conn, output)
  end
  def create(conn, %{"command" => command}) do
    output = execute(command, [])
    json(conn, output)
  end

  defp execute(command, args) do
    {output, exit_code} = System.cmd(command, args)
    %{"command" => command, "args" => args, "output" => output, "exit_code" => exit_code}
  end
end
