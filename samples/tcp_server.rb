require 'logger'
require 'time'
require_relative '../lib/em/gserver'

port = ARGV[0].to_i
port = 2000 if port <= 0

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

logger = Logger.new('logs/tcp_server.log')
opts = {
    :port => port, 
    :handler => MyConnection,
    :logger => logger,
    :heartbeat_timeout => 1.0,
    :max_connections => 10,
}
listeners = [ EventMachine::GServer::Listeners::TcpListener.new(opts) ]
server = MyServer.new('tcp_server', listeners: listeners, logger: logger)
server.start