module EventMachine
    module GServer
        module Listeners
            
            #
            # @author Marcos Ortiz
            # Implements a Unix Listener.
            #
            class UnixListener < EventMachine::GServer::Listeners::Base

                #
                # @param [Hash] opts the options for creating this class.
                # @option opts [String] :socket_path ('/tmp/test_socket') The unix file to be used.
                #
                def initialize(opts={})
                    super(opts)
                end
                
                #
                # Stops the server.
                #
                def start_server
                    @signature = EM.start_unix_domain_server(@socket_path, @handler) do |connection|
                      setup_connection_opts(connection)
                    end
                    log(:info, "Started listener #{@signature} on #{@socket_path} (separator=#{@separator.inspect}).")
                    super
                end
                
                def stop(force=false)
                    super(force)
                    if File.exists?(@socket_path)
                        File.delete(@socket_path)
                        log(:info, "Successfully deleted socket file #{@socket_path}.")
                    end
                end
                
                private
            
                def setup_opts(opts)
                    super(opts)
                    @socket_path = opts[:socket_path] || EventMachine::GServer::DEFAULT_SOCKET_PATH
                end
            end
        end
    end
end