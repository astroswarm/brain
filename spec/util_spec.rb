require 'spec_helper'

require_relative '../util'

RSpec.describe Util do
  describe '#execute_command' do
    it 'executes command with arguments and returns output' do
      result = Util.execute_command('echo', ['hi there!'])

      expect(result[:output]).to eq("hi there!\n")
      expect(result[:exit_code]).to equal(0)
    end
    it 'executes command without arguments and returns output' do
      result = Util.execute_command('false')

      expect(result[:output]).to eq("")
      expect(result[:exit_code]).to equal(1)
    end
  end

  describe '#get_serial_number' do
    it 'returns a 12-digit serial number' do
      expect(Util.get_serial_number.length).to equal(12)
    end
  end

  describe 'private methods' do
    describe '#load_host_data_file' do
      it "returns contents of specified file" do
        expect(Util.send :load_host_data_file, 'lan_ip_address').to eql(`cat /host-data/lan_ip_address`)
      end
    end
  end

  it '#running_webapplications returns hash with file_manager and container_manager' do
    containers = %w(file_manager portainer)
    containers.each do |c|
      expect(Docker::Container.all(all: true, filters: {name: ["astrolab_#{c}_1"]}.to_json).count).to eql(1)
    end

    response = Util.running_webapplications
    expect(response.count).to eql(2)
  end

  xdescribe 'xapplication i/o' do
    before do
      @phd2_image = "astroswarm/phd2:latest"
      VCR.turn_off!
      WebMock.allow_net_connect!

      begin
        Docker::Image.get @phd2_image
      rescue Docker::Error::NotFoundError
        raise "Before running these tests, please run: docker pull #{@phd2_image}"
      end
    end
    after do
      WebMock.disable_net_connect!
      VCR.turn_on!
    end

    def wait_until(&block)
      max_time = 60
      started_at = Time.now
      until !!block.call
        if Time.now > started_at + max_time
          raise "Condition was not reached in under #{max_time} seconds"
        else
          sleep 0.1
        end
      end
    end

    it 'start_xapplication, stop_xapplication, clean_xapplication' do
      containers = %w(localtunnel websockify xapplication)
      containers.each do |c|
        expect(Docker::Container.all(all: true, filters: {name: ["phd2_#{c}_1"]}.to_json).count).to eql(0)
      end

      Util.start_xapplication @phd2_image

      containers.each do |c|
        wait_until do
          Docker::Container.all(all: true, filters: {name: ["phd2_#{c}_1"], status: ['running']}.to_json).count == 1
        end
      end

      Util.stop_xapplication @phd2_image

      containers.each do |c|
        wait_until do
          Docker::Container.all(all: true, filters: {name: ["phd2_#{c}_1"], status: ['exited']}.to_json).count == 1
        end
      end

      Util.clean_xapplication @phd2_image

      containers.each do |c|
        wait_until do
          Docker::Container.all(all: true, filters: {name: ["phd2_#{c}_1"]}.to_json).count == 0
        end
      end
    end

    it '#running_xapplications returns hash with endpoints' do
      containers = %w(localtunnel websockify xapplication)
      containers.each do |c|
        expect(Docker::Container.all(all: true, filters: {name: ["phd2_#{c}_1"]}.to_json).count).to eql(0)
      end

      Util.start_xapplication @phd2_image

      containers.each do |c|
        wait_until do
          Docker::Container.all(all: true, filters: {name: ["phd2_#{c}_1"], status: ['running']}.to_json).count == 1
        end
      end

      # Wait until the tunnel is up to proceed
      wait_until {HTTParty.get("http://phd2_localtunnel_1:8080").body != ""}

      response = Util.running_xapplications
      expect(response.count).to eql(1)

      app = response.first
      expect(app[:name]).to eql('phd2')
      expect(app[:local_vnc_endpoint]).to match(/^vnc\:\/\/\d+\.\d+\.\d+\.\d+\:\d+$/)
      expect(app[:local_websockify_endpoint]).to match(/^http\:\/\/\d+\.\d+\.\d+\.\d+\:\d+$/)
      expect(app[:remote_websockify_endpoint]).to match(/^https\:\/\/[a-z]+\.localtunnel.me$/)


      Util.clean_xapplication @phd2_image
      containers.each do |c|
        wait_until do
          Docker::Container.all(all: true, filters: {name: ["phd2_#{c}_1"]}.to_json).count == 0
        end
      end
    end

    it '#running_xapplications returns only endpoints that are available' do
      containers = %w(localtunnel websockify xapplication)
      containers.each do |c|
        expect(Docker::Container.all(all: true, filters: {name: ["phd2_#{c}_1"]}.to_json).count).to eql(0)
      end

      Util.start_xapplication @phd2_image

      wait_until do
        Docker::Container.all(all: true, filters: {name: ["phd2_xapplication_1"], status: ['running']}.to_json).count == 1
      end

      # Rely on websockify endpoints not being ready yet

      response = Util.running_xapplications
      expect(response.count).to eql(1)

      app = response.first
      expect(app[:name]).to eql('phd2')
      expect(app[:local_vnc_endpoint]).to match(/^vnc\:\/\/\d+\.\d+\.\d+\.\d+\:\d+$/)
      expect(app[:local_websockify_endpoint]).to be_nil
      expect(app[:remote_websockify_endpoint]).to be_nil


      Util.clean_xapplication @phd2_image
      containers.each do |c|
        wait_until do
          Docker::Container.all(all: true, filters: {name: ["phd2_#{c}_1"]}.to_json).count == 0
        end
      end
    end
  end
end
