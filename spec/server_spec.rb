require 'spec_helper'

require_relative '../server'

RSpec.describe AstrolabServer do
  it 'responds with 200 to status check' do
    get '/status'
    expect(last_response.body).to eq("OK")
    expect(last_response.status).to equal(200)
  end

  describe '/api' do
    describe '/execute_command' do
      it 'executes command with arguments and returns output' do
        post '/api/execute_command', {
          command: 'echo',
          args: ["hi there!"]
        }.to_json

        expect(JSON.parse(last_response.body)["output"]).to eq("hi there!\n")
        expect(JSON.parse(last_response.body)["exit_code"]).to equal(0)
      end
      it 'executes command without arguments and returns output' do
        post '/api/execute_command', {
          command: 'false'
        }.to_json

        expect(JSON.parse(last_response.body)["output"]).to eq("")
        expect(JSON.parse(last_response.body)["exit_code"]).to equal(1)
      end
    end
    describe '/heartbeat' do
      it 'registers the astrolab and returns the response' do
        VCR.use_cassette('heartbeat', :allow_unused_http_interactions => false) do
          post '/api/heartbeat'
          expect(last_response.body).to eq('{"data":{"id":"11","type":"astrolabs","links":{"self":"http://172.19.0.1:3001/v1/astrolabs/11"},"attributes":{"last-public-ip-address":"172.18.0.1","last-private-ip-address":"127.0.0.1","last-seen-at":"2017-06-19T00:33:53.529Z","last-country-name":"","last-region-name":"","last-city":"","last-zip-code":"","last-time-zone":"","last-latitude":0.0,"last-longitude":0.0,"created-at":"2017-06-18T03:21:39.940Z","updated-at":"2017-06-19T00:33:53.533Z"}}}')
        end
      end
    end
  end
end
