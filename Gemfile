source 'https://rubygems.org'

# Specify your gem's dependencies in gserver.gemspec
gemspec

git 'https://github.com/marcosortiz/easy_daemons' do
    gem 'easy_daemons'
end

group :test do
  gem 'rspec'
  gem 'codeclimate-test-reporter', require: nil
  gem 'easy_sockets', '~> 1.0.0'
end