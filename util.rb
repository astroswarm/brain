require 'docker'
require 'httparty'

class Util
  ARCH = `uname -m`.strip
  EXPECTED_VNC_PORT = 5900
  EXPECTED_WEBSOCKIFY_PORT = 6900
  LOCALTUNNEL_ENDPOINT_EXPOSURE_PORT = 8080
  SHARED_ROOT = '/mnt/shared'

  class << self
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

    def post_heartbeat
      HTTParty.post("http://#{ENV['ASTROSWARM_API_HOST']}/v1/astrolabs",
        headers: {
          "Content-Type" => "application/vnd.api+json"
        },
        body: {
          "data" => {
            "type" => "astrolabs",
            "attributes" => {
              "serial-number" => get_serial_number,
              "private-ip-address" => get_lan_ip_address,
              "tunnel-endpoint" => get_localtunnel_endpoint('astrolab')
            }
          }
        }.to_json)
    end

    def get_serial_number
      execute_command('cat /sys/class/net/eth0/address | sed s/\://g')[:output].strip
    end

    def get_lan_ip_address
      load_host_data_file('lan_ip_address').strip
    end

    def clean_xapplication(image)
      name = get_name_of_docker_image(image)

      filepath = "#{ENV['HOME']}/#{name}.yml"

      fork_and_run_detached "docker-compose -f #{filepath} -p #{name} down"
    end

    def start_xapplication(image)
      name = get_name_of_docker_image(image)

      compose_content = generate_compose_content_for_xapplication(image)

      filepath = "#{ENV['HOME']}/#{name}.yml"
      File.open(filepath, 'w') do |file|
        file.write compose_content
      end

      fork_and_run_detached "mkdir -p #{get_shared_path_for_xapplication(name)}"
      fork_and_run_detached "docker-compose -f #{filepath} -p #{name} up"
    end

    def stop_xapplication(image)
      name = get_name_of_docker_image(image)

      filepath = "#{ENV['HOME']}/#{name}.yml"

      fork_and_run_detached "docker-compose -f #{filepath} -p #{name} stop"
    end

    def running_xapplications
      applications = []

      Docker::Container.all(all: true, filters: { name: ["xapplication"] }.to_json).each do |xapplication_container|
        application_name = xapplication_container.info["Names"].first.split('/')[1].split('_')[0]

        websockify_container = Docker::Container.all(all: true, filters: { label: ["com.docker.compose.project=#{application_name}", "com.docker.compose.service=websockify"] }.to_json).first
        local_websockify_endpoint =
          if websockify_container.nil?
            nil
          else
            websockify_public_port = websockify_container.info["Ports"].keep_if{
              |hash| hash["PrivatePort"] == EXPECTED_WEBSOCKIFY_PORT
            }.first["PublicPort"]
            "http://#{get_lan_ip_address}:#{websockify_public_port}"
          end

        xapplication_container = Docker::Container.all(all: true, filters: { label: ["com.docker.compose.project=#{application_name}", "com.docker.compose.service=xapplication"] }.to_json).first
        vnc_public_port = xapplication_container.info["Ports"].keep_if{
          |hash| hash["PrivatePort"] == EXPECTED_VNC_PORT
        }.first["PublicPort"]
        vnc_endpoint = "vnc://#{get_lan_ip_address}:#{vnc_public_port}"

        applications << {
          name: application_name,
          local_vnc_endpoint: vnc_endpoint,
          local_websockify_endpoint: local_websockify_endpoint,
          remote_websockify_endpoint: get_localtunnel_endpoint(application_name)
        }
      end

      applications
    end

    private

    def fork_and_run_detached(command)
      pid = Process.fork
      if pid.nil?
        exec command
      else
        Process.detach(pid)
      end
    end

    def get_shared_path_for_xapplication(application_name)
      "#{SHARED_ROOT}/#{application_name}/shared"
    end

    def get_localtunnel_endpoint(compose_project)
      localtunnel_container = Docker::Container.all(all: true, filters: { label: ["com.docker.compose.project=#{compose_project}", "com.docker.compose.service=localtunnel"] }.to_json).first
      if localtunnel_container
        localtunnel_name = localtunnel_container.info["Names"].first.split('/')[1]
        HTTParty.get("http://#{localtunnel_name}:#{LOCALTUNNEL_ENDPOINT_EXPOSURE_PORT}").body.strip
      else
        nil
      end
    end

    def generate_compose_content_for_xapplication(docker_image)
      <<~EOS
      version: '3'
      networks:
        default:
          external:
            name: astrolab_default
      services:
        xapplication:
          image: #{docker_image}
          ports:
            - "#{EXPECTED_VNC_PORT}/tcp"
          privileged: true
          restart: unless-stopped
          volumes:
            - "/dev/bus/usb:/dev/bus/usb"
            - "#{get_shared_path_for_xapplication(get_name_of_docker_image(docker_image))}:/shared"
        websockify:
          depends_on:
            - xapplication
          environment:
            VNC_HOST: xapplication
            VNC_PORT: #{EXPECTED_VNC_PORT}
          image: astroswarm/websockify-#{ARCH}:latest
          ports:
            - "#{EXPECTED_WEBSOCKIFY_PORT}/tcp"
          restart: unless-stopped
        localtunnel:
          depends_on:
            - websockify
          environment:
            HTTP_HOST: websockify
            HTTP_PORT: #{EXPECTED_WEBSOCKIFY_PORT}
          image: astroswarm/localtunnel_client-#{ARCH}:latest
          restart: unless-stopped
      EOS
    end

    def get_name_of_docker_image(image)
      # Handle all the different ways "myprogram" could be specified as a valid docker image:
      name = if image.include?('/') && image.include?(':')
        image.split('/')[1].split(':')[0] # repository/myprogram:latest
      elsif image.include?('/')
        image.split('/')[1] # repository/myprogram
      elsif image.include?(':')
        image.split(':')[0] # myprogram:latest
      else
        image # myprogram
      end

      # Remove ARCH qualifier when it's amended to the end of the name
      name.chomp("-#{ARCH}")
    end

    def load_host_data_file(filename)
      File.open("#{ENV['HOST_DATA_DIR']}/#{filename}", "rb").read
    end
  end
end
