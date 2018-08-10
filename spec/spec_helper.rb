require "bundler/setup"
require "squash_matrix"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # config.after(:client_test) { puts "sleeping for 3 seconds"; sleep 3 }

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
