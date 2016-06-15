# EventMachine::GServer [![Build Status](https://travis-ci.org/marcosortiz/em-gserver.svg?branch=dev)](https://travis-ci.org/marcosortiz/em-gserver) [![Dependency Status](https://gemnasium.com/badges/github.com/marcosortiz/em-gserver.svg)](https://gemnasium.com/github.com/marcosortiz/em-gserver)

The em-gserver gem provides an easy way to implement customisable servers that can run several instances of TCP, UDP and Unix listeners.

It uses [eventmachine](https://github.com/eventmachine/eventmachine) and was inspired by the [gserver](https://github.com/ruby/gserver) gem.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'em-gserver'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install em-gserver

## Usage

TODO: Write usage instructions here

## Development [![Code Climate](https://codeclimate.com/github/marcosortiz/em-gserver/badges/gpa.svg)](https://codeclimate.com/github/marcosortiz/em-gserver) [![Test Coverage](https://codeclimate.com/github/marcosortiz/em-gserver/badges/coverage.svg)](https://codeclimate.com/github/marcosortiz/em-gserver/coverage)

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcosortiz/em-gserver.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
