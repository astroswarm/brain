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
  end
end
