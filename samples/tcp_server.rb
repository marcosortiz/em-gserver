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

opts = {
    :port => port, 
    :handler => MyConnection,
    :logger => Logger.new(STDOUT),
    :heartbeat_timeout => 1.0,
    :max_connections => 10,
}
listeners = []
listeners << EventMachine::GServer::Listeners::TcpListener.new(opts)
opts[:listeners] = listeners


server = MyServer.new(opts)
server.run