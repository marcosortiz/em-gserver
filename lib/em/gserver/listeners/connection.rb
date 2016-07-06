module EventMachine
    module GServer
        module Listeners
            class Connection < EM::Connection
                include EventMachine::GServer::Utils
                attr_accessor :logger, :server, :separator, :default_error_resp
                
                def unbind
                    server.connections.delete(self) unless server.nil?
                end
    
                def do_work(request)
                    'OK'
                end

                def receive_data(data)
                    log(:debug, "Received: #{data.inspect}.")
                    (@buffer ||= '') << data
                    offset = 0
                    requests = []
                    last_index = nil

                    #
                    # parse requests based on @separator
                    #
                    while index = @buffer.index(@separator, offset)
                        requests << req = @buffer[offset..index-1]
                        offset = index + @separator.size
                        last_index = index
                    end

                    #
                    # Process each request
                    #
                    requests.each do |req|
                        process(req)
                    end

                    #
                    # Remove processed requests from buffer.
                    #
                    unless last_index.nil?
                        last_offset = last_index + @separator.size
                        @buffer = @buffer[last_offset..-1]
                    end
                    log(:debug, "Left on @buff: #{@buffer.inspect}") unless @buffer.empty?
                end

                private

                def process(request)
                    EM.defer do
                        resp = ''
                        begin
                            resp = do_work(request)
                            resp << @separator unless @separator.nil? || resp.end_with?(@separator)
                            log(:debug, "Replying with #{resp.inspect}.")
                            send_data(resp)
                            resp
                        rescue Exception => e
                            error_msg = "#{e.class}: #{e.message}"
                            backtrace = e.backtrace.join("\n")
                            log(:error, error_msg)
                            log(:error, backtrace)
                            log(:error, "Replying with #{@default_error_resp.inspect}")
                            send_data('internal error'+CRLF)
                        end
                    end
                end
            end
        end
    end
end