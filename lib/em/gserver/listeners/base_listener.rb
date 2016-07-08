require 'em/gserver/listeners/connection'

module EventMachine
    module GServer
        module Listeners
            class Base
                include EventMachine::GServer::Utils
        
                attr_accessor :connections, :stop_requested, :host, :port, :socket_path, :server
                attr_reader :status, :started_at, :logger, :inactivity_timeout,
                    :connection_timeout, :signature, :max_connections, :default_error_resp
                
                DEFAULT_INACTIVITY_TIMEOUT = 5.0 # seconds
                DEFAULT_CONNECTION_TIMEOUT = 5.0 # seconds
                DEFAILT_MAX_CONNECTIONS    = 5
                DEFAULT_ERROR_RESP         = 'internal error'
        
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
        
                def stop(force=false)
                    return if @status == STOPPED_SYM
                    is_udp = self.class == EventMachine::GServer::Listeners::UdpListener
                    force = true if is_udp
                    if force == true
                        EventMachine.next_tick do
                            @connections.each do |conn|
                                log(:info, "Forced stop requested. Closing connection #{conn.signature}")
                                conn.close_connection(false)
                            end
                            EM.stop_server(@signature) unless is_udp
                            log(:info, "Listener #{@signature} gracefully stopped.")
                            @status = STOPPED_SYM
                        end
                    else
                        EventMachine.next_tick do
                            unless wait_for_connections_and_stop
                                # Still some connections running, schedule a check later
                                EM.add_periodic_timer(1) { wait_for_connections_and_stop }
                            end
                        end
                    end
                end

                private

                def setup_opts(opts)
                    @logger = opts[:logger]
                    
                    @handler = opts[:handler] || EventMachine::GServer::Listeners::Connection
                    check_handler
                    
                    @separator = opts[:separator] || CRLF
                    @separator = nil if opts[:no_msg_separator] == true
                    
                    @inactivity_timeout = opts[INACTIVITY_TIMEOUT_SYM].to_f
                    @inactivity_timeout = DEFAULT_INACTIVITY_TIMEOUT if @inactivity_timeout <= 0.0
                
                    @connection_timeout = opts[CONNECTION_TIMEOUT_SYM].to_f
                    @connection_timeout = DEFAULT_CONNECTION_TIMEOUT if @connection_timeout <= 0.0
                    
                    @max_connections = opts[MAX_CONNECTIONS_SYM].to_i
                    @max_connections = DEFAILT_MAX_CONNECTIONS if @max_connections <=0
                    
                    @default_error_resp = opts[DEFAULT_ERROR_RESP_SYM] || DEFAULT_ERROR_RESP
                end
        
                def start_server
                    @status = RUNNING_SYM
                    @started_at = Time.now.utc
                end

                def setup_connection_opts(connection, set_timeouts=false)
                    if connections.count >= @max_connections
                        msg = "Can not open more than #{@max_connections} simulatenous connections."
                        msg << "Connection #{connection.signature} discarded."
                        connection.close_connection(false)
                        log(:warn, msg)
                    else
                        connections << connection
                        log(:debug, "Listener #{@signature} received a client connection (id=#{connection.signature}).")
                        connection.logger = @logger
                        connection.server = self
                        connection.separator = @separator
                        connection.comm_inactivity_timeout = @inactivity_timeout if set_timeouts
                        connection.pending_connect_timeout = @connection_timeout if set_timeouts
                        connection.default_error_resp = @default_error_resp
                    end
                end

                def wait_for_connections_and_stop
                    if @connections.empty?
                        EM.stop_server(@signature)
                        log(:info, "Server #{@signature} gracefully stopped.")
                        true
                    else
                        log(:info, "Listener #{@signature } waiting for #{@connections.size} connection(s) to finish ...")
                        false
                    end
                end

                def stop_server_if_requested
                    stop if stop_requested
                end

                def check_handler
                    return if @handler <= EventMachine::GServer::Listeners::Connection
                    msg = "#{@handler} is not a subclass of SK::Workers::Listeners::Connection."
                    raise InvalidHandlerClass.new(msg)
                end
            end
        end
    end
end