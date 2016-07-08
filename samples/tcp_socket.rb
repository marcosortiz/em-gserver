require  'easy_sockets'
require 'logger'

port = ARGV[0].to_i
port = 2000 if port <= 0

connections = []
10.times do |i|
    puts "#{i+1}) Connecting ..."
    c = EasySockets::TcpSocket.new( {:host => '127.0.0.1', :port => port, :logger => Logger.new(STDOUT)} )
    resp = c.send_msg("#{i+1}")
    p "Got: #{resp} (#{resp.class})"
    connections << c
    sleep 0.25
end

while true
    sleep 1
end
