require 'logger'
require 'time'
require_relative '../lib/em/gserver'

class MyConnection < EventMachine::GServer::Listeners::Connection
    def do_work(req)
        req
    end
end

class MyServer < EventMachine::GServer::Base

    def do_work
        EventMachine.next_tick do
            EM.add_periodic_timer(1) do
                msg = ""
                listeners.each do |l|
                    msg << "listener #{l.signature} connections=#{l.connections.count}"
                    msg << ',' unless l == listeners.last
                end
                log(:info, msg)
            end
        end
    end
    
end

logger = Logger.new('logs/unix_server.log')
opts = {
    :socket_path => './test_soket',
    :handler => MyConnection,
    :logger => logger,
    :heartbeat_timeout => 1.0,
    :max_connections => 10,
}
listeners = [ EventMachine::GServer::Listeners::UnixListener.new(opts) ]

server = MyServer.new('unix_server', logger: logger, listeners: listeners)
server.start