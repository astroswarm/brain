module Util
  ARCH = `uname -m`.strip
  EXPECTED_VNC_PORT = 5900
  EXPECTED_WEBSOCKIFY_PORT = 6900

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

  def get_serial_number
    execute_command('cat /sys/class/net/eth0/address | sed s/\://g')[:output].strip
  end
  module_function :get_serial_number

  def launch_xapplication(image)
    repo = image.split('/')[0]
    name = image.split('/')[1].split(':')[0]
    tag = image.split('/')[1].split(':')[1]

    compose_content = generate_compose_content_for_xapplication(image)
    filepath = "#{ENV['HOME']}/#{name}.yml"
    File.open(filepath, 'w') do |file|
      file.write compose_content
    end
  end
  module_function :launch_xapplication

  # private
  def generate_compose_content_for_xapplication(docker_image)
    <<~EOS
      version: '3'
      services:
        xapplication:
          image: #{docker_image}
          ports:
            - "#{EXPECTED_VNC_PORT}/tcp"
        websockify:
          depends_on:
            - xapplication
          environment:
            VNC_HOST: xapplication
            VNC_PORT: #{EXPECTED_VNC_PORT}
          image: astroswarm/websockify-#{ARCH}:latest
          ports:
            - #{EXPECTED_WEBSOCKIFY_PORT}/tcp
        localtunnel:
          depends_on:
            - websockify
          environment:
            WEBSOCKIFY_HOST: websockify
            WEBSOCKIFY_PORT: #{EXPECTED_WEBSOCKIFY_PORT}
          image: astroswarm/localtunnel-#{ARCH}:latest
    EOS
  end
  module_function :generate_compose_content_for_xapplication
end
