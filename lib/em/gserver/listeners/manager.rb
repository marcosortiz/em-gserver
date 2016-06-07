require File.join(File.dirname(__FILE__), '..', 'constants')
require File.join(File.dirname(__FILE__), 'tcp', 'tcp_listener')
require File.join(File.dirname(__FILE__), 'udp', 'udp_listener')
require File.join(File.dirname(__FILE__), 'unix', 'unix_listener')


module EventMachine
    module GServer
        module Listeners
            module Manager
                
                LISTENERS_CLASSES = [
                    EventMachine::GServer::Listeners::TcpListener,
                    EventMachine::GServer::Listeners::UdpListener,
                    EventMachine::GServer::Listeners::UnixListener,
                ]
                
                private
                                
                def set_listeners(opts)
                    @listeners = []
                    if opts[LISTENERS_SYM] && opts[LISTENERS_SYM].is_a?(Array)
                        opts[LISTENERS_SYM].each do |listener|
                            check_listener_class(listener)
                            @listeners << listener
                        end
                    end
                end
                
                def stop_listeners
                    @listeners.each do |listener|
                        next if listener.nil?
                        listener.stop
                    end
                end
                
                def start_listeners
                    @listeners.each do |listener|
                        next if listener.nil?
                        listener.start
                    end
                end
                
                def check_listener_class(listener)
                    LISTENERS_CLASSES.each do |klass|
                        return if listener.class <= klass
                    end
                    fail "#{listener.class} is not a valid listener class."
                end                
            end
        end
    end
end