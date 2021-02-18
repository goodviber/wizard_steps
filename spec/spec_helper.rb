require "bundler/setup"

require 'active_support/concern'
require 'active_support/core_ext/module'
require 'active_model'
require 'active_support/core_ext/array/wrap'

require "wizard_steps/wizard/store"
require "wizard_steps/wizard/base"
require "wizard_steps/wizard/step"
require "support/shared_examples/wizard_support"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
