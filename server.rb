require 'json'
require 'sinatra/base'
require 'sinatra/namespace'
require 'logger'
require 'httparty'

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

      execute_command(command, args).to_json
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
              "serial-number" => "SN001",
              "last-private-ip-address" => "127.0.0.1"
            }
          }
        }.to_json

      status response.code
      response.body
    end
  end

  get '/status' do
    'OK'
  end

  private
  def execute_command(command, args)
    output = `#{command} #{args.map{|a| "\"#{a}\""}.join(' ')}`
    exit_code = $?.exitstatus
    
    {
      command: command,
      args: args,
      output: output,
      exit_code: exit_code
    }
  end
end
