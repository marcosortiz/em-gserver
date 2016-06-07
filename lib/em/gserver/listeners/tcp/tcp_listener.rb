require 'eventmachine'
require File.join(File.dirname(__FILE__), '..', 'base_listener')

module EventMachine
    module GServer
        module Listeners
            class TcpListener < EventMachine::GServer::Listeners::Base

                def initialize(opts={})
                    super(opts)
                end
        
                def start_server
                    @signature = EM.start_server(@host, @port, @handler) do |connection|
                      setup_connection_opts(connection)
                    end
                    log(:info, "Started #{@signature} linstening on tcp://#{@host}:#{@port} (separator=#{@separator.inspect}).")
                    super
                end
        
                # def stop
                #     EM.stop_server(@signature)
                #     log(:info, "Server #{@signature} gracefully stopped listening on tcp://#{@host}:#{@port}.")
                #     super
                # end

                private
        
                def setup_opts(opts)
                    super(opts)
                    @port = opts[:port].to_i || EventMachine::GServer::DEFAULT_PORT
                    @port = EmServer::DEFAULT_PORT if @port <= 0
                    @host = opts[:host] || EventMachine::GServer::DEFAULT_HOST
                end
        
            end
        end
    end
end