require File.join(File.dirname(__FILE__), '..', 'base_listener')

module EventMachine
    module GServer
        module Listeners
            class UnixListener < EventMachine::GServer::Listeners::Base
            end
        end
    end
end