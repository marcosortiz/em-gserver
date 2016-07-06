require 'em/gserver/listeners/base_listener'
require 'em/gserver/listeners/tcp/tcp_listener'
require 'em/gserver/listeners/udp/udp_listener'
require 'em/gserver/listeners/unix/unix_listener'


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
                            listener.server = self
                            @listeners << listener
                        end
                    end
                end
                
                def stop_listeners(force=false)
                    @listeners.each do |listener|
                        next if listener.nil?
                        listener.stop(force)
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
                    msg = "#{listener.class} is not a valid listener class."
                    raise EventMachine::GServer::InvalidListener.new msg
                end                
            end
        end
    end
end