module Util
  def execute_command(command, args = [])
    output = `#{command} #{args.map{|a| "\"#{a}\""}.join(' ')}`
    exit_code = $?.exitstatus

    {
      command: command,
      args: args,
      output: output,
      exit_code: exit_code
    }
  end
  module_function :execute_command
  
  def load_host_data_file(filename)
    File.open("#{ENV['HOST_DATA_DIR']}/#{filename}", "rb").read
  end
  module_function :load_host_data_file
end
