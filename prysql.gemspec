# -*- encoding: utf-8 -*-
require File.expand_path('../lib/prysql/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'prysql'
  s.version     = Prysql::VERSION

  s.summary     = 'Pry mysql interface'
  s.description = 'An extension to Pry that provides a SQL interface within the pry session'

  s.authors     = ['Josh Aronson (jaronson)']
  s.email       = 'jparonson@gmail.com'
  s.homepage    = 'http://github.com/jaronson/prysql'

  s.files       = Dir[
    'Gemfile',
    '{bin,lib,spec}/**/*',
    'README*',
    'LICENSE*'
  ] & `git ls-files -z`.split("\0")
end
