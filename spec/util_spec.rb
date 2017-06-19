require 'spec_helper'

require_relative '../util'

RSpec.describe Util do
  include Util

  describe 'Util methods' do
    describe '#load_host_data_file' do
      it "returns contents of specified file" do
        expect(load_host_data_file 'lan_ip_address').to eql(`cat /host-data/lan_ip_address`)
      end
    end
  end
end
