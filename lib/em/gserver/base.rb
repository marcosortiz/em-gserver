require 'em/gserver/constants'
require 'em/gserver/exceptions'
require 'em/gserver/utils'
require 'em/gserver/version'
require 'em/gserver/listeners/manager'

module EventMachine
    module GServer
        
        #
        # @author Marcos Ortiz
        # Implements an evented generic server that can have spin up multiple
        # TCP, UDP and Unix listeners.
        #
        class Base
            include EventMachine::GServer::Utils
            include EventMachine::GServer::Listeners::Manager
            include EasyDaemons::Helper
            
            DEFAULT_STOP_TIMEOUT               = 5.0 # seconds
            DEFAULT_HEARTBEAT_TIMEOUT          = 2.0 # seconds
            
            attr_reader :name, :pid_file_path, :pid, :logger, :listeners, :stopping, :stop_timeout,
                :heartbeat_interval, :status
            
            #
            # @param [Hash] opts the options for creating this class.
            # @option opts [Logger] :logger (nil) An instance of Logger.
            # @option opts [Float] :stop_timeout (5) Timeout in seconds for the server to wait for open connections to close before closing them and stopping the server.
            # @option opts [Float] :heartbeat_timeout (2) How often to check for dead connections.
            # @option opts [Array] :listeners An array of instances of subclasses of {EventMachine::GServer::Listeners::Base}. 
            #
            def initialize(name, opts={})
                @name = name
                set_opts(opts)
                set_listeners(opts)
                @status = STOPPED_SYM
                @stopping = false
                @stop_wait_count = 0
            end
            
            #
            # This method will be called when the server starts. You can use it
            # to run periodic work.
            #
            def do_work
            end
            
            #
            # Starts the server.
            #
            # Note that this is an idempotent operation. That is, you can call
            # it several times. If the server is not running, it will run it.
            # Otherwise it will just return the current (:running) status.
            #
            def run
                return @status unless @status == STOPPED_SYM
                @status = STARTING_SYM
                register_error_handler
                EM.run do
                    register_trap_signals
                    set_heartbeat_timeout(@heartbeat_timeout)
                    start_listeners
                    stop_reactor_if_all_listeners_stopped
                    do_work
                    log(:info, "EventMachine::GServer up and running with pid=#{Process.pid}.")
                    @status = RUNNING_SYM
                end
            end
            
            #
            # This method simply runs the run method as a daemon background process.
            #
            def start
                if is_already_running?(@name)
                    log(:info, "Process #{@name} is already running.")
                    exit(1)
                end
                log(:info, "Starting #{@name} worker in the background ...")
                daemonize(@name)
                @pid = curr_pid
                log(:info, "#{@name} worker successfully started in the background (pid=#{@pid}).")
                log(:info, "Refreshing #{@pid_file_path} file with #{@pid}.")
                refresh_pid_file(@pid_file_path, @pid)
                log(:info, "#{@pid_file_path} successfully created with #{@pid}.")
                run
            end

            #
            # Stops the server. 
            #
            # Note that this is an idempotent operation. That is, you can call
            # it several times. If the server is running, it will stop it.
            # Otherwise it will just return the current (:stopped) status.
            #
            # @param force [Boolean] Defaults to false. If true, will close any
            # open connection before stopping. Otherwise, it will wait up until
            # stop_timeout for all open connection to be closed before stopping.
            def stop(force=false)
                return @status unless @status == RUNNING_SYM
                @status = STOPPING_SYM
                @stopping = true
                stop_listeners(force)
                EventMachine.stop if force == true && EventMachine.reactor_running?
                @status = STOPPED_SYM
            end

            private
            
            def set_opts(opts={})
                @logger = opts[:logger]
                
                @stop_timeout = opts[STOP_TIMEOUT_SYM].to_f
                @stop_timeout = DEFAULT_STOP_TIMEOUT if @stop_timeout <= 0.0
                
                @heartbeat_timeout = opts[HEARTBEAT_TIMEOUT_SYM].to_f
                @heartbeat_timeout = DEFAULT_HEARTBEAT_TIMEOUT if @heartbeat_timeout <= 0.0
                
                @pid_file_path = opts[:pid_file_path] || "pids/#{@name}.pid"
            end
            
            #
            # Log any exception thrown on the main reactor loop
            #
            def register_error_handler
                EM.error_handler do |e|
                    log(:error, "#{e.class}: #{e.message}")
                    log(:error, e.backtrace.join("\n"))
                    stop(true)
                    raise e
                end
            end
            
            # Registering trap signals so we stop EM properly
            def register_trap_signals(signals=[:INT, :QUIT, :TERM])
                signals.each do |signal|
                    Signal.trap(signal) do
                        t = Thread.new do
                            stop
                            remove_pid_file(@pid_file_path)
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