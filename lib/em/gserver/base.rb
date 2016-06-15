module EventMachine
    module GServer
        class Base
            include EventMachine::GServer::Utils
            include EventMachine::GServer::Listeners::Manager
            
            DEFAULT_STOP_TIMEOUT               = 5.0 # seconds
            DEFAULT_HEARTBEAT_TIMEOUT          = 2.0 # seconds
            
            attr_reader :logger, :listeners, :stopping, :stop_timeout,
                :heartbeat_interval
            
            def initialize(opts={})
                set_opts(opts)
                set_listeners(opts)
                @stopping = false
                @stop_wait_count = 0
            end
            
            def do_work
            end
            
            def start
                return if EventMachine.reactor_running?
                register_error_handler
                EM.run do
                    register_trap_signals
                    set_heartbeat_timeout(@heartbeat_timeout)
                    start_listeners
                    stop_reactor_if_all_listeners_stopped
                    do_work
                    logger.info "EventMachine::GServer up and running with pid=#{Process.pid}. Press Ctrl+C to quit."
                end
            end

            def stop
                @stopping = true
                stop_listeners
            end

            private
            
            def set_opts(opts={})
                @logger = opts[:logger]
                
                @stop_timeout = opts[STOP_TIMEOUT_SYM].to_f
                @stop_timeout = DEFAULT_STOP_TIMEOUT if @stop_timeout <= 0.0
                
                @heartbeat_timeout = opts[HEARTBEAT_TIMEOUT_SYM].to_f
                @heartbeat_timeout = DEFAULT_HEARTBEAT_TIMEOUT if @heartbeat_timeout <= 0.0
            end
            
            #
            # Log any exception thrown on the main reactor loop
            #
            def register_error_handler
                EM.error_handler do |e|
                    logger.error "#{e.class}: #{e.message}"
                    logger.error e.backtrace.join("\n")
                    raise e
                end
            end
            
            # Registering trap signals so we stop EM properly
            def register_trap_signals(signals=[:INT, :QUIT, :TERM])
                signals.each do |signal|
                    Signal.trap(signal) do
                        t = Thread.new do
                            stop
                        end
                        t.join
                    end
                end
            end
            
            def stop_reactor_if_all_listeners_stopped
                EventMachine.next_tick do
                    EventMachine.add_periodic_timer(1) do
                        EventMachine.stop if should_stop?
                        @stop_wait_count += 1 if @stopping
                    end
                end
            end
            
            def should_stop?
                resp = false
                if EventMachine.get_connection_count == 0
                    resp = true
                elsif @stopping && @stop_wait_count > @stop_timeout
                    log(:warn, "Forcing server stop (stop timeout is #{@stop_timeout} seconds).")
                    resp = true
                end
                resp
            end
            
            def set_heartbeat_timeout(timeout)
                if EventMachine.reactor_running?
                    EventMachine.heartbeat_interval = timeout
                end
            end
            
        end
    end
end