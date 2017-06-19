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
end
