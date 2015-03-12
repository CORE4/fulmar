# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fulmar/version'

Gem::Specification.new do |spec|
  spec.name          = 'fulmar'
  spec.version       = Fulmar::VERSION
  spec.authors       = ['Jonas Siegl', 'Gerrit Visscher']
  spec.email         = %w(j.siegl@core4.de g.visscher@core4.de)
  spec.summary       = %q{A deployment task manager.}
  spec.description   = %q{Fulmar is a task manager for deployments.}
  spec.homepage      = 'http://git.core4.de/core4internal/fulmar'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
end
