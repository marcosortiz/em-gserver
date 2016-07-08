module EventMachine
    module GServer
        module Listeners
            
            #
            # @author Marcos Ortiz
            # Implements a TCP Listener.
            #
            class TcpListener < EventMachine::GServer::Listeners::Base

                #
                # @param [Hash] opts the options for creating this class.
                # @option opts [String] :host ('127.0.0.1') IP address to listen on.
                # @option opts [Fixnum] :port (2000) The port to listen on.
                #
                def initialize(opts={})
                    super(opts)
                end
                
                #
                # Initiates a TCP server (socket acceptor) on the specified IP address and port.
                # The IP address must be valid on the machine where the program
                # runs, and the process must be privileged enough to listen on
                # the specified port (on Unix-like systems, superuser privileges
                # are usually required to listen on any port lower than 1024).
                # Only one listener may be running on any given address/port
                # combination. start_server will fail if the given address and
                # port are already listening on the machine, either because of a
                # prior call to start_server or some unrelated process running on
                # the machine. If start_server succeeds, the new network listener
                # becomes active immediately and starts accepting connections from
                # remote peers, and these connections generate callback events that
                # are processed by the code specified in the handler parameter to
                # start_server.
                #
                def start_server
                    @signature = EM.start_server(@host, @port, @handler) do |connection|
                      setup_connection_opts(connection)
                    end
                    log(:info, "Started listener #{@signature} on tcp://#{@host}:#{@port} (separator=#{@separator.inspect}).")
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