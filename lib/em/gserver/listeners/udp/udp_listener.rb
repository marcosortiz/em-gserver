module EventMachine
    module GServer
        module Listeners
            class UdpListener < EventMachine::GServer::Listeners::Base

                def initialize(opts={})
                    super(opts)
                end
            
                def start_server
                    EM.open_datagram_socket(@host, @port, @handler) do |connection|
                        @signature = connection.signature
                        setup_connection_opts(connection, false)
                    end
                    log(:info, "Started listener #{@signature} on udp://#{@host}:#{@port} (separator=#{@separator.inspect}).")
                    super
                end
                
                private
            
                def setup_opts(opts)
                    super(opts)
                    @port = opts[:port].to_i || EventMachine::GServer::DEFAULT_PORT
                    @port = EventMachine::GServer::DEFAULT_PORT if @port <= 0
                    @host = opts[:host] || EventMachine::GServer::DEFAULT_HOST
                end
            end
        end
    end
end