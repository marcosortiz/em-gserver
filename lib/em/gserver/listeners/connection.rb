require 'eventmachine'
require File.join(File.dirname(__FILE__), '..', 'constants')
require File.join(File.dirname(__FILE__), '..', 'utils')

module EventMachine
    module GServer
        module Listeners
            class Connection < EM::Connection
                include EventMachine::GServer::Utils
                attr_accessor :logger, :server, :separator
        
                def post_init
            
                end
        
                def unbind
                    server.connections.delete(self)
                end
    
                def do_work(cmd_hash)
                    'OK'
                end

                private
    
                def receive_data(cmd)
                    server.connections << self
                    cmd.chomp!(@separator) if @separator
                    log(:debug, "Received: #{cmd.inspect}.")
                    process(cmd)
                end
    
                def process(command)
                    EM.defer do
                        resp = ''
                        begin
                            resp = do_work(command)
                            resp << CRLF unless resp.end_with?(CRLF)
                        rescue Exception => e
                            error_msg = "#{e.class}: #{e.message}"
                            backtrace = e.backtrace.join("\n")
                            log(:error, error_msg)
                            log(:error, backtrace)
                        end
                        log(:debug, "Replying with #{resp.inspect}.")
                        send_data(resp)
                        resp
                    end 
                end
            end
        end
    end
end