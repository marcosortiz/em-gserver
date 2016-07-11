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

opts = {
    :socket_path => './test_soket',
    :handler => MyConnection,
    :logger => Logger.new(STDOUT),
    :heartbeat_timeout => 1.0,
    :max_connections => 10,
}
listeners = [ EventMachine::GServer::Listeners::UnixListener.new(opts) ]
opts[:listeners] = listeners

server = MyServer.new(opts)
server.run