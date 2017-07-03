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

  describe '#load_host_data_file' do
    it "returns contents of specified file" do
      expect(Util.load_host_data_file 'lan_ip_address').to eql(`cat /host-data/lan_ip_address`)
    end
  end

  describe 'xapplication i/o' do
    before do
      @phd2_image = "astroswarm/phd2-x86_64:latest"
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
      started_at = Time.now
      until !!block.call
        if Time.now > started_at + 30
          raise "Condition was not reached in under 30 seconds"
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
  end
end
