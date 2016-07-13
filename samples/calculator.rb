require 'logger'
require 'time'
require_relative '../lib/em/gserver'

port = ARGV[0].to_i
port = 2000 if port <= 0

class CalculatorConnection < EventMachine::GServer::Listeners::Connection
    
    def receive_data(data)
        log(:debug, "Received: #{data.inspect}.")
        init_variables
        
        data.each_char do |ch|
            next if ["\r", "\n"].include?(ch)
            if @status == :initializing
                @status = :num1 if ch == '('
            elsif @status == :num1
                if ['+', '-', '/', '*'].include?(ch)
                    @operation << ch
                    @status = :num2
                else
                    @num1 << ch 
                end
            elsif @status == :num2
                if ch == ')'
                    @status = :ready
                else
                    @num2 << ch
                end
            end
            
            msg = status_string
            log(:debug, "current operation: #{msg}") unless msg.empty?
            
            if @status == :ready
                process_operation(@num1, @operation, @num2)
                reset_variables
            end
        end
    end
    
    private
    
    def init_variables
        @num1 ||= ''
        @num2 ||= ''
        @operation ||= ''
        @status ||= :initializing
    end
    
    def reset_variables
        @num1 = ''
        @num2 = ''
        @operation = ''
        @status = :initializing
    end
    
    def process_operation(num1, operation, num2)
        begin
            resp = "#{num1.to_f.send(operation, num2.to_f).round(6)}"
            log(:debug, "Replying with #{resp.inspect}.")
            send_data(resp)
        rescue Exception => e
            log(:error, "#{e.class}: #{e.message}")
            log(:error, e.backtrace.join("\n"))
        end
    end
    
    def status_string
        s = ''
        s << "(" unless @status == :initializing
        s << "#{@num1}" unless @num1.empty?
        s << " #{@operation} " unless @operation.empty?
        s << "#{@num2}" unless @num2.empty?
        s << ")" if @status == :ready
        s
    end
    
end

opts = {
    :port => port, 
    :handler => CalculatorConnection,
    :logger => Logger.new(STDOUT),
    :heartbeat_timeout => 1.0,
    :max_connections => 10,
}

opts[:port] += port
listeners = [ EventMachine::GServer::Listeners::TcpListener.new(opts) ]
opts[:listeners] = listeners
server = EventMachine::GServer::Base.new(opts)
server.run