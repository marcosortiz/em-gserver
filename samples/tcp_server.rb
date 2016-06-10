require 'logger'
require 'time'
require_relative '../lib/em/gserver'

port = ARGV[0].to_i
port = 2000 if port <= 0

class MyConnection < EventMachine::GServer::Listeners::Connection
    def do_work(msg)
        msg
    end
end

class MyServer < EventMachine::GServer::Base

    def do_work
        EventMachine.next_tick do
            EM.add_periodic_timer(1) do
                log(:info, "Doing my periodic work ...")
            end
        end
    end
    
end

opts = {
    :port => port, 
    :handler => MyConnection,
    :logger => Logger.new(STDOUT),
}
listeners = []
2.times do |i|
    opts[:port] += i
    listeners << EventMachine::GServer::Listeners::TcpListener.new(opts)
end
opts[:listeners] = listeners


server = MyServer.new(opts)
server.start