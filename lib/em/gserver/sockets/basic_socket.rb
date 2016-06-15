require 'socket'
require 'timeout'
require 'em/gserver'
require 'em/gserver/constants'

module EventMachine
    module GServer
        class BasicSocket
            include EventMachine::GServer::Utils
            
            attr_reader :logger
    
            DEFAULT_TIMEOUT = 0.5
    
            def initialize(opts={})
                setup_opts(opts)
            end
    
            def connect
                return if @connected && (@socket && !@socket.closed?)
                on_connect
                @connected = true
            end

            def disconnect
                return unless @connected
                if @socket && !@socket.closed?
                    log(:debug, "Disconnecting socket ...")
                    @socket.close 
                    log(:debug, "Socket successfully disconnected.")
                    @connected = false
                end
            end
    
            def on_connect
            end
    
            def send_msg(msg)
                msg_to_send = msg.dup
                msg_to_send << @separator unless @separator.nil? || msg.end_with?(@separator)

                # This is an idempotent operation
                connect

                log(:debug, "Sending #{msg.inspect}.")
                send(msg_to_send)
        
                resp = receive_msg
                log(:debug, "Got #{resp.inspect}.")
                resp
            # Raised by some IO operations when reaching the end of file. Many IO methods exist in two forms,
            # one that returns nil when the end of file is reached, the other raises EOFError EOFError.
            # EOFError is a subclass of IOError.
            rescue EOFError
                log(:info, "Server disconnected.")
                self.disconnect
            # "Connection reset by peer" is the TCP/IP equivalent of slamming the phone back on the hook.
            # It's more polite than merely not replying, leaving one hanging.
            # But it's not the FIN-ACK expected of the truly polite TCP/IP converseur.
            rescue Errno::ECONNRESET => e
                log(:info, 'Connection reset by peer.')
                self.disconnect
                raise e
            rescue Exception => e
                @socket.close if @socket && !@socket.closed?
                raise e
            end
    
            private
    
            def setup_opts(opts)
                @timeout = opts[:timeout].to_f || DEFAULT_TIMEOUT
                @timeout = DEFAULT_TIMEOUT if @timeout <= 0
                @separator = opts[:separator] || CRLF
                @separator = nil if opts[:no_msg_separator] == true
                @logger = opts[:logger]
            end
    
            def send(msg)
                @socket.sendmsg(msg)
            end
    
            def receive_msg
                resp = ''
                begin
                    resp << @socket.read_nonblock(CHUNK_SIZE)
                    while @separator && !resp.end_with?(@separator) do
                        resp << @socket.read_nonblock(CHUNK_SIZE)
                    end
                    resp
                rescue Errno::EAGAIN
                    if IO.select([@socket], nil, nil, @timeout)
                        retry
                    else
                        self.disconnect
                        raise Timeout::Error, "No response within #{@timeout} seconds."
                    end
                rescue EOFError => e
                    log(:info, "Server disconnected.")
                    self.disconnect
                    raise e
                end
            end
        end
    end
end
