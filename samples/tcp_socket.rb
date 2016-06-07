require_relative '../lib/em/gserver/sockets/tcp/tcp_socket'

port = ARGV[0].to_i
port = 2000 if port <= 0

c1 = EventMachine::GServer::TCPSocket.new( {:host => '127.0.0.1', :port => port} )
c2 = EventMachine::GServer::TCPSocket.new( {:host => '127.0.0.1', :port => port+1} )

10.times do |i|
    puts "c1: #{c1.send_msg("#{i+1}")}"
    puts "c2: #{c2.send_msg("#{i+1}")}"
end

while true
    sleep 1
end
