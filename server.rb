require 'json'
require 'sinatra/base'
require 'sinatra/namespace'
require 'logger'

require_relative 'util'
require_relative 'wifi'

class AstrolabServer < Sinatra::Base
  register Sinatra::Namespace

  configure do
    enable :logging

    set :protection, :except => :frame_options # We anticipate public assets being loaded from iframes
  end

  options "*" do
    response.headers['Allow'] = 'HEAD,GET,PUT,DELETE,OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'
    response.headers['Access-Control-Allow-Origin'] = "*"
    200
  end

  namespace '/api' do
    before do
      headers['Access-Control-Allow-Origin'] = "*"
    end

    # With great power comes great irresponsibility. Remove this prior to public
    # release. I'm leaving as is until then for more rapid feature development.
    # Once use cases are known, move this to a private library and generate
    # endpoints to invoke specific features.
    post '/execute_command' do
      payload = JSON.parse(request.body.read)

      command = payload['command']
      args = payload['args'] || []

      Util.execute_command(command, args).to_json
    end

    post '/upload_logs' do
      response = Util.execute_command(
        "pastebinit",
        ["-b", ENV['PASTEBINIT_URI'], "/mnt/host/var/log/syslog"]
      )

      {
        url: response[:output].match(/https?\:\/\/.*\/raw/)[0]
      }.to_json
    end

    post '/heartbeat' do
      response = Util.post_heartbeat

      status response.code
      response.body
    end

    post '/clean_xapplication' do
      payload = JSON.parse(request.body.read)
      Util.clean_xapplication(payload['image'])

      status 200
      {"status" => "OK"}.to_json
    end

    post '/start_xapplication' do
      payload = JSON.parse(request.body.read)
      Util.start_xapplication(payload['image'])
      
      status 200
      {"status" => "OK"}.to_json
    end

    post '/stop_xapplication' do
      payload = JSON.parse(request.body.read)
      Util.stop_xapplication(payload['image'])

      status 200
      {"status" => "OK"}.to_json
    end

    get '/running_xapplications' do
      response = Util.running_xapplications.to_json

      status 200
      response
    end

    get '/running_webapplications' do
      response = Util.running_webapplications.to_json

      status 200
      response
    end

    post '/add_wifi_network' do
      payload = JSON.parse(request.body.read)
      Wifi.add_network payload['ssid'], payload['key']

      status 200
      {"status" => "OK"}.to_json
    end
    post '/remove_wifi_network' do
      payload = JSON.parse(request.body.read)
      Wifi.remove_network payload['ssid']

      status 200
      {"status" => "OK"}.to_json
    end
    get '/wifi_networks' do
      response = Wifi.list_networks.to_json

      status 200
      response
    end
  end

  get '/status' do
    'OK'
  end
end
