require 'docker'

module Util
  # The port on which we expect a VNC server to be running within a container
  VNC_PRIVATE_PORT = 5900
  WEBSOCKIFY_PRIVATE_PORT = 6900

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


  def remote_enable_xapplications
    containers = running_xapplication_containers
    containers.each do |xapplication_container|
      ensure_websockify_exists_for_xapplication_container(xapplication_container)
      ensure_localtunnel_exists_for_xapplication_container(xapplication_container)
    end

    # Return array of applications and everything needed to access them remotely.
    
  end
  module_function :remote_enable_xapplications

  def prune_old_xapplications

  end

  private

  def running_xapplication_containers
    Docker::Container.all.keep_if do |c|
      is_container_running_vnc_server?(c)
    end
  end

  def get_websockify_container_name(xapplication_container)
    "#{xapplication_container.info["Names"].sort.first}-websockify"
  end
  def get_localtunnel_container_name(xapplication_container)
    "#{xapplication_container.info["Names"].sort.first}-localtunnel"
  end

  def ensure_websockify_exists_for_xapplication_container(xapplication_container)
    containers = Docker::Container.all(
      all: true,
      filters: {
        "name" => get_websockify_container_name(xapplication_container)
      }
    )

    if containers.count == 0
      launch_websockify_for_xapplication_container(xapplication_controller)
    end
  end

  def ensure_localtunnel_exists_for_xapplication_container(xapplication_container)
    containers = Docker::Container.all(
      all: true,
      filters: {
        "name" => get_localtunnel_container_name(xapplication_container)
      }
    )

    if containers.count == 0
      launch_localtunnel_for_xapplication_container(xapplication_controller)
    end
  end

  def launch_websockify_for_xapplication_container(xapplication_container)
    websockify_container = Docker::Container.create(
      "name" => get_websockify_container_name(xapplication_container),
      "Image" => "astroswarm/websockify-x86_64:latest",
      "PublishAllPorts" => true,
      "Env" => [
        "VNC_HOST=0.0.0.0",
        "VNC_PORT=#{get_container_public_port_mapping(xapplication_container, VNC_PRIVATE_PORT)}"
      ],
      "RestartPolicy" => {
        "Name" => "unless-stopped"
      }
    )

    websockify_container.start
  end

  def launch_localtunnel_for_xapplication_container(xapplication_container)
    websockify_container = Docker::Container.all(
      all: true,
      filters: {
        "name" => get_websockify_container_name(xapplication_container)
      }
    ).first

    websockify_port = get_container_public_port_mapping(websockify_container, WEBSOCKIFY_PRIVATE_PORT)

    localtunnel_container = Docker::Container.create(
      "name" => get_localtunnel_container_name(xapplication_container),
      "Image" => "astroswarm/localtunnel-x86_64:latest",
      "PublishAllPorts" => true,
      "Env" => [
        "HTTP_PORT_TO_TUNNEL=#{websockify_port}",
      ],
      "RestartPolicy" => {
        "Name" => "unless-stopped"
      }
    )
    localtunnel_container.start
  end

  def get_container_public_port_mapping(container, private_port)
    return -1 if !container.info.has_key?("Ports")

    container.info["Ports"].each do |port_mapping|
      return port_mapping["PublicPort"] if port_mapping["PrivatePort"] == private_port
    end

    return -2
  end
  def is_container_running_vnc_server?(container)
    hash = container.info
    if hash["Ports"]
      hash["Ports"].each do |port_mapping|
        if port_mapping["PrivatePort"] == VNC_PRIVATE_PORT
          return true
        end
      end
    end

    false
  end

end
