$:.push File.expand_path("../lib", __FILE__)
require 'date'
require 'vindata/version'

Gem::Specification.new do |s|
  s.name        = 'vindata'
  s.version     = VinData::VERSION
  s.date        = Date.today.to_s
  s.platform    = Gem::Platform::RUBY
  s.summary     = %q{Query popular VIN databases to get vehicle information.}
  s.description = %q{Library which queries vehicle databases such as Edmunds for publicly available vehicle information using VIN number}
  s.authors     = ["Roupen Mouradian"]
  s.email       = 'roupen@acdcorp.com'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/orgs/acdcorp/'
end
