require_relative 'lib/wizard_steps/version'

Gem::Specification.new do |spec|
  spec.name          = "wizard_steps"
  spec.version       = WizardSteps::VERSION
  spec.authors       = ["maxmills"]
  spec.email         = ["8balldigitalsolutions@gmail.com"]

  spec.summary       = %q{ helps to create multi-step forms typical of gov.uk forms }
  spec.description   = %q{ Need a longer description here }
  spec.homepage      = "http://www.example.com"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "http://www.example.com"
  spec.metadata["changelog_uri"] = "http://www.example.com"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
