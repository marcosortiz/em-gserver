source 'https://rubygems.org'

# Specify your gem's dependencies in gserver.gemspec
gemspec

group :test do
  gem 'rspec'
  gem "codeclimate-test-reporter", require: nil
  git 'https://github.com/marcosortiz/easy_sockets.git', :branch => 'dev' do
      gem 'easy_sockets'
  end
end