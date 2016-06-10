require 'em/gserver/listeners/connection'

module EventMachine
    module GServer
        module Listeners
            class Base
                include EventMachine::GServer::Utils
        
                attr_accessor :connections, :stop_requested, :host, :port, :socket_path
                attr_reader :status, :started_at, :logger
        
                def initialize(opts={})
                    setup_opts(opts)
                    @connections = []
                    @stop_requested = false
                    @status = STOPPED_SYM
                end
        
                def start
                    EventMachine.next_tick do
                        EM.add_periodic_timer(1) do
                            stop_server_if_requested
                        end
                    end

                    start_server
                end
        
                def stop
                    @status = STOPPED_SYM
                    EventMachine.next_tick do
                        unless wait_for_connections_and_stop
                            # Still some connections running, schedule a check later
                            EM.add_periodic_timer(1) { wait_for_connections_and_stop }
                        end
                    end
                end

                private

                def setup_opts(opts)
                    @logger = opts[:logger]
                    @handler = opts[:handler] || EmServer::Connection
                    @separator = opts[:separator] || CRLF
                    @separator = nil if opts[:no_msg_separator] == true
                    check_handler
                end
        
                def start_server
                    @status = RUNNING_SYM
                    @started_at = Time.now.utc
                end

                def setup_connection_opts(connection)
                    connection.logger = @logger
                    connection.server = self
                    connection.separator = @separator
                end

                def wait_for_connections_and_stop
                    if @connections.empty?
                        EM.stop_server(@signature)
                        log(:info, "Server #{@signature} gracefully stopped.")
                        true
                    else
                        log(:info, "Server #{@signature } waiting for #{@connections.size} connection(s) to finish ...")
                        false
                    end
                end

                def stop_server_if_requested
                    stop if stop_requested
                end

                def check_handler
                    return if @handler <= EventMachine::GServer::Listeners::Connection
                    msg = "#{@handler} is not a subclass of SK::Workers::Listeners::Connection."
                    fail msg
                end
            end
        end
    end
end