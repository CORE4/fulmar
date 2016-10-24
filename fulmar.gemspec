# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fulmar/version'

Gem::Specification.new do |spec|
  spec.name          = 'fulmar'
  spec.version       = Fulmar::VERSION
  spec.authors       = ['Jonas Siegl', 'Gerrit Visscher']
  spec.email         = %w(j.siegl@core4.de g.visscher@core4.de)
  spec.summary       = 'A deployment task manager.'
  spec.description   = 'Fulmar is a task manager for deployments.'
  spec.homepage      = 'https://github.com/CORE4/fulmar'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'

  spec.add_runtime_dependency 'rake', '~>10'
  spec.add_runtime_dependency 'rugged', '~> 0.23.0'
  spec.add_runtime_dependency 'mysql2', '~>0.3'
  spec.add_runtime_dependency 'fulmar-shell', '~>1', '>=1.7.0'
  spec.add_runtime_dependency 'ruby_wings', '~>0.1', '>=0.1.1'
  spec.add_runtime_dependency 'colorize', '~>0'
end
