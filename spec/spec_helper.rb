require 'rack/test'
require 'vcr'
require 'webmock'

def app
  AstrolabServer
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_request do |request|
    ignore = false
    host = URI(request.uri).host

    # Assume domain-less hosts are docker containers
    ignore = true if !host.include? ('.')
    # Assume hard-coded IP addresses are local docker containers
    ignore = true if host =~ /^\d+\.\d+\.\d+\.\d+$/

    ignore
  end
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.filter_run_when_matching :focus

  config.example_status_persistence_file_path = 'spec/examples.txt'

  config.disable_monkey_patching!

  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.order = :random     

  Kernel.srand config.seed
end
