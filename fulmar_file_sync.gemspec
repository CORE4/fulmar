# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name          = 'fulmar_file_sync'
  s.version       = '0.1.0'
  s.date          = '2015-03-05'
  s.summary       = 'CORE4 file syncing tool'
  s.description   = 'This gem adds file sync functionality to the fulmar deployment tool. It can be used standalone though.'
  s.authors       = ['Gerrit Visscher']
  s.email         = 'g.visscher@core4.de'
  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  s.homepage      = 'http://git.core4.lan/core4internal/fulmar_file_sync'
  s.license       = 'proprietary'
  s.require_paths = ['lib']
end