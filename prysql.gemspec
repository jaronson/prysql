# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name    = 'prysql'
  s.version = '0.0.1'

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.authors     = ['Josh Aronson (jaronson)']
  s.date        = '2012-04-27'
  s.description = 'A ruby console for mysql'
  s.email       = 'jparonson@gmail.com'
  s.files       = [ '.gitignore','Gemfile', 'lib/prysql.rb']
  s.homepage    = 'http://github.com/jaronson/prysql'
  s.summary     = 'An interactive ruby console for mysql'

  if s.respond_to?(:specification_version)
    s.specification_version = 3
  end
end
