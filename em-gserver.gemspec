# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'em/gserver/version'

Gem::Specification.new do |spec|
  spec.name          = "em-gserver"
  spec.version       = EventMachine::GServer::VERSION
  spec.authors       = ["Marcos Ortiz"]
  spec.email         = ["marcos.ortiz@icloud.com"]

  spec.summary       = %q{Implements easy to use tcp, udp and unix servers and clients.}
  spec.description   = %q{Implements easy to use tcp, udp and unix servers and clients.}
  spec.homepage      = "https://github.com/marcosortiz/em-gserver"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency('eventmachine')
  
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.5"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'timecop'
end
