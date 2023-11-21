require_relative 'lib/wizard_steps/version'

Gem::Specification.new do |spec|
  spec.name          = "wizard_steps"
  spec.version       = WizardSteps::VERSION
  spec.author        = "Max Mills"
  spec.email         = ["8balldigitalsolutions@gmail.com"]
  spec.license       = "MIT"

  spec.summary       = %q{ A helper module to create multi-step forms typical of gov.uk forms }
  spec.description   = %q{ A helper module for multi-step inputs typical of gov.uk forms. See the README for full instructions. }
  spec.homepage      = "https://github.com/goodviber/wizard_steps"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata['allowed_push_host'] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end

