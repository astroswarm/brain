class Wifi
  WPA_SUPPLICANT_PATH = '/mnt/host/etc/wpa_supplicant/wpa_supplicant.conf'

  def self.add_network(ssid, key = nil)
    key = nil if key == ""
    remove_network ssid
    
    lines = load_wpa_supplicant
    lines << 'network={'
    lines << %Q{  ssid="#{ssid}"}
    if key
      lines << %Q{  psk="#{key}"}
    else
      lines << '  key_mgmt=NONE'
    end
    lines << '}'

    write_wpa_supplicant(lines)
  end

  def self.remove_network(ssid)
    lines = load_wpa_supplicant
    starts_at = 0
    ends_at = 0
    active = false

    lines.each_with_index do |line, line_number|
      if line.include?("network={")
        starts_at = line_number
        active = false
      elsif line.include?(%Q{ssid="#{ssid}"})
        active = true
      elsif line.chomp == '}'
        ends_at = line_number
        break if active
      end
    end

    if active
      lines.slice!(starts_at..ends_at)
      write_wpa_supplicant(lines)
    end
  end

  def self.list_networks
    lines = load_wpa_supplicant
    networks = []
    active = false

    lines.each_with_index do |line, line_number|
      if line.include?("network={")
        active = true
      elsif active && line.include?(%Q{ssid="})
        networks << /ssid="(.*)"/.match(line)[1]
      elsif line.chomp == '}'
        active = false
      end
    end

    networks
  end

  private
  class << self
    def write_wpa_supplicant(lines)
      File.open(WPA_SUPPLICANT_PATH, 'w') do |f|
        lines.each do |line|
          f.puts line
        end
      end
    end

    def load_wpa_supplicant
      file_lines = []
      File.open(WPA_SUPPLICANT_PATH, 'r') do |f|
        f.each_line do |line|
          file_lines << line
        end
      end

      file_lines
    end
  end
end
