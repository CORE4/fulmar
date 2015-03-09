# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name        = 'deploy'
  s.version     = '0.1.0'
  s.date        = '2015-03-05'
  s.summary     = 'CORE4 deployment tool'
  s.description = 'Deployment tool to transfer files and possibly other data to another host'
  s.authors     = ['Gerrit Visscher']
  s.email       = 'g.visscher@core4.de'
  s.files       = %w(bin/deploy lib/deploy.rb lib/transfer/base.rb lib/transfer/rsync_with_versions.rb)
  s.homepage    = 'http://git.core4.lan/core4internal/deploy'
  s.license     = 'proprietary'
end