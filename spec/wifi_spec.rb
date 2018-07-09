require 'spec_helper'

require_relative '../wifi'

RSpec.describe Wifi do
  describe '#add_network and #remove_network integration' do
    it 'adds and removes numerically-named networks' do
      File.open(Wifi::WPA_SUPPLICANT_PATH, 'w') {|file| file.truncate 0}

      expect(Wifi.list_networks).to eql([])
      expect(File.read(Wifi::WPA_SUPPLICANT_PATH)).to eql <<~END
      END

      Wifi.add_network "1"
      Wifi.add_network "2"
      Wifi.add_network "3"
      Wifi.add_network "4"
      Wifi.add_network "5"

      Wifi.remove_network "3"
      expect(Wifi.list_networks).to eql(["1","2","4","5"])
      Wifi.remove_network "2"
      expect(Wifi.list_networks).to eql(["1","4","5"])
      Wifi.remove_network "5"
      expect(Wifi.list_networks).to eql(["1","4"])
      Wifi.remove_network "4"
      expect(Wifi.list_networks).to eql(["1"])
      Wifi.remove_network "1"
      expect(Wifi.list_networks).to eql([])
    end
    it 'adds networks in order, removes them from within file, gracefully handles removal failures' do
      File.open(Wifi::WPA_SUPPLICANT_PATH, 'w') {|file| file.truncate 0}

      expect(Wifi.list_networks).to eql([])
      expect(File.read(Wifi::WPA_SUPPLICANT_PATH)).to eql <<~END
      END

      Wifi.add_network "network1", "password"
      Wifi.add_network "network2", "pass2"
      Wifi.add_network "network3"
      Wifi.add_network "network4", "originalpassword"
      Wifi.add_network "network4", ""

      expect(Wifi.list_networks).to eql(["network1", "network2", "network3", "network4"])
      expect(File.read(Wifi::WPA_SUPPLICANT_PATH)).to eql <<~END
        network={
          ssid="network1"
          psk="password"
        }
        network={
          ssid="network2"
          psk="pass2"
        }
        network={
          ssid="network3"
          key_mgmt=NONE
        }
        network={
          ssid="network4"
          key_mgmt=NONE
        }
      END

      Wifi.remove_network "network3"
      expect(Wifi.list_networks).to eql(["network1", "network2", "network4"])
      expect(File.read(Wifi::WPA_SUPPLICANT_PATH)).to eql <<~END
        network={
          ssid="network1"
          psk="password"
        }
        network={
          ssid="network2"
          psk="pass2"
        }
        network={
          ssid="network4"
          key_mgmt=NONE
        }
      END

      Wifi.remove_network "banana"
      expect(Wifi.list_networks).to eql(["network1", "network2", "network4"])
      expect(File.read(Wifi::WPA_SUPPLICANT_PATH)).to eql <<~END
        network={
          ssid="network1"
          psk="password"
        }
        network={
          ssid="network2"
          psk="pass2"
        }
        network={
          ssid="network4"
          key_mgmt=NONE
        }
      END

      Wifi.remove_network "network1"
      expect(Wifi.list_networks).to eql(["network2", "network4"])
      expect(File.read(Wifi::WPA_SUPPLICANT_PATH)).to eql <<~END
        network={
          ssid="network2"
          psk="pass2"
        }
        network={
          ssid="network4"
          key_mgmt=NONE
        }
      END

      Wifi.remove_network "network4"
      expect(Wifi.list_networks).to eql(["network2"])
      expect(File.read(Wifi::WPA_SUPPLICANT_PATH)).to eql <<~END
        network={
          ssid="network2"
          psk="pass2"
        }
      END

      Wifi.remove_network "network2"
      expect(Wifi.list_networks).to eql([])
      expect(File.read(Wifi::WPA_SUPPLICANT_PATH)).to eql <<~END
      END

      Wifi.remove_network "banana"
      expect(Wifi.list_networks).to eql([])
      expect(File.read(Wifi::WPA_SUPPLICANT_PATH)).to eql <<~END
      END
    end
  end
end
