require 'spec_helper'
require 'em/gserver'

describe EventMachine::GServer do
    it 'has a version number' do
        expect(EventMachine::GServer::VERSION).not_to be nil
    end
end
