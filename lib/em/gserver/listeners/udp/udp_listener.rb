module EventMachine
    module GServer
        module Listeners
            
            #
            # @author Marcos Ortiz
            # Implements a UDP Listener.
            #
            class UdpListener < EventMachine::GServer::Listeners::Base

                #
                # @param [Hash] opts the options for creating this class.
                # @option opts [String] :host ('127.0.0.1') IP address to listen on.
                # @option opts [Fixnum] :port (2000) The port to listen on.
                #
                def initialize(opts={})
                    super(opts)
                end

                #
                # This method will create a new UDP (datagram) socket and bind
                # it to the address and port that you specify.
                #
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