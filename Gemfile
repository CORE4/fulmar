source 'https://rubygems.org'

# Specify your gem's dependencies in fulmar.gemspec
gemspec

group :test do
  gem 'rake'
  gem 'rspec'
  gem 'fakefs', require: 'fakefs/safe'
end

group :test, :development do
  gem 'rubocop', require: false
end
