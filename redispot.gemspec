# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redispot/version'

Gem::Specification.new do |spec|
  spec.name          = 'redispot'
  spec.version       = Redispot::VERSION
  spec.authors       = ['hatyuki']
  spec.email         = ['hatyuki29@gmail.com']
  spec.summary       = 'Launching the redis-server instance which is available only within a block.'
  spec.description   = 'Launching the redis-server instance which is available only within a block.'
  spec.homepage      = 'https://github.com/hatyuki/redispot-rb'
  spec.license       = 'MIT'
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^test/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'redis'
  spec.add_development_dependency 'test-unit'
  spec.add_development_dependency 'yard'
end
