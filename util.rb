module Util
  def load_host_data_file(filename)
    File.open("/host-data/#{filename}", "rb").read
  end
end
