require 'json'
require 'sinatra/base'
require 'sinatra/namespace'
require 'logger'
require 'httparty'

require_relative 'util'

class AstrolabServer < Sinatra::Base
  register Sinatra::Namespace

  configure do
    enable :logging
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

    post '/heartbeat' do
      response = HTTParty.post "http://#{ENV['ASTROSWARM_API_HOST']}/v1/astrolabs",
        headers: {
          "Content-Type" => "application/vnd.api+json"
        },
        body: {
          "data" => {
            "type" => "astrolabs",
            "attributes" => {
              "serial-number" => Util.get_serial_number,
              "last-private-ip-address" => Util.get_lan_ip_address
            }
          }
        }.to_json

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
  end

  get '/status' do
    'OK'
  end
end
