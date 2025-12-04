require_relative "lib/sidekiq_solid_fetch/version"

Gem::Specification.new do |spec|
  spec.name = "sidekiq_solid_fetch"
  spec.version = SidekiqSolidFetch::VERSION
  spec.authors = ["Alex Koval"]
  spec.email = ["al3xander.koval@gmail.com"]

  spec.summary = "OSS implementation of Sidekiq Pro's `super_fetch`"
  spec.description = "OSS implementation of Sidekiq Pro's `super_fetch`"
  spec.homepage = "https://github.com/k0va1/sidekiq_solid_fetch"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/k0va1/sidekiq_solid_fetch/blob/master/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq", ">= 7.0"
end
