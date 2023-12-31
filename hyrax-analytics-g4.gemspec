# frozen_string_literal: true

require_relative "lib/hyrax/analytics/g4/version"

Gem::Specification.new do |spec|
  spec.name = "hyrax-analytics-g4"
  spec.version = Hyrax::Analytics::G4::VERSION
  spec.authors = ["Jeremy Friesen"]
  spec.email = ["jeremy.n.friesen@gmail.com"]

  spec.summary = "A prototype and hopeful replacement for Hyrax's use of Legato."
  spec.description = "A prototype and hopeful replacement for Hyrax's use of Legato."
  spec.homepage = "https://github.com/scientist-softserv/hyrax-analytics-g4"
  spec.required_ruby_version = ">= 2.6.0"

  spec.license = "APACHE-2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activesupport'
  spec.add_development_dependency 'google-analytics-data'

  spec.add_development_dependency 'bixby'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'pry'
end
