require 'spec_helper'
require 'time'
require 'timecop'

describe EventMachine::GServer::Listeners::UnixListener do
    let :logger do
        Logger.new("#{TEST_LOGS_PATH}/my_unix_server.log")
    end
    
    let :socket_path do
        "#{TEST_LOGS_PATH}/test_socket1"
    end
    
    let :template_opts do
        listeners = [
            described_class.new(logger: logger, socket_path: socket_path)
        ]
        { 
            logger: logger,
            listeners: listeners,
        }
    end

    
    def server(opts={})
        EventMachine::GServer::Base.new(template_opts.merge(opts))
    end
    
    def client(opts={})
        default_opts = {
            socket_path: socket_path,
            timeout: 0.1,
            logger: Logger.new("#{TEST_LOGS_PATH}/my_unix_client.log"),
        }
        EasySockets::UnixSocket.new(default_opts.merge(opts))
    end
    
    def wait_for_status(server, status, timeout = 3)
        t0 = Time.now
        while server.status != status
            msg = "Server status never changed to #{status} in #{timeout} seconds."
            fail msg if Time.now-t0 > timeout
            sleep 0.01
        end
    end
    
    def start_server(s)
        t = Thread.new { s.start }
        wait_for_status(s, EventMachine::GServer::RUNNING_SYM)
        t.join(0.01)
        t
    end
    
    def stop_server(server, thread)
        server.stop(true)
        thread.join
        wait_for_status(server, EventMachine::GServer::STOPPED_SYM)
    end
    
    def listener(server)
        server.listeners.first
    end
    
    describe 'initialization' do
        it 'must initialize internal variables and options properly' do
            s = server
            l = listener(s)
            expect(l.instance_variable_get(:@handler)).to eq(EventMachine::GServer::Listeners::Connection)
            expect(l.instance_variable_get(:@separator)).to eq EventMachine::GServer::CRLF
            expect(l.inactivity_timeout).to eq EventMachine::GServer::Listeners::Base::DEFAULT_INACTIVITY_TIMEOUT
            expect(l.connection_timeout).to eq EventMachine::GServer::Listeners::Base::DEFAULT_CONNECTION_TIMEOUT
            expect(l.max_connections).to eq EventMachine::GServer::Listeners::Base::DEFAILT_MAX_CONNECTIONS
            expect(l.default_error_resp).to eq EventMachine::GServer::Listeners::Base::DEFAULT_ERROR_RESP
            expect(l.connections).to eq([])
            expect(l.status).to eq EventMachine::GServer::STOPPED_SYM
            expect(l.started_at).to be nil
        end
        context 'with invalid handler class specified' do
            
            let :invalid_class do
                Fixnum
            end
            
            let :opts do
                listeners = [
                    described_class.new(logger: logger, handler: invalid_class)
                ]
                { listeners: listeners }
            end
            
            it 'must raise InvalidHandlerClass' do
                expect {
                    s = server(opts)
                }.to raise_error(EventMachine::GServer::InvalidHandlerClass, /#{invalid_class}/)
            end
        end
    end
    describe 'starting' do
        
        after :each do
            Timecop.return
        end
        
        let :t0 do
            Time.parse('2016-07-07T10:00:00Z')
        end
        
        it 'must properly set the started_at and status fields and create socket file' do
            s = server
            l = listener(s)
            expect(l.status).to eq EventMachine::GServer::STOPPED_SYM
            
            3.times do |i|
                Timecop.freeze(t0+i)
                expect(File.exists?(socket_path)).to be false
                t = start_server(s)
                expect(l.status).to eq EventMachine::GServer::RUNNING_SYM
                expect(l.started_at).to eq t0+i
                sleep 0.3
                expect(File.exists?(socket_path)).to be true
                stop_server(s, t)
            end
        end
    end
    describe 'request processing' do
        
        let :count do
            10
        end
        
        let :separator do
            EventMachine::GServer::CRLF
        end
        
        let :msg_arr do
            arr = []
            count.times do |i|
                arr << "#{i}"
            end
            arr << separator
            arr
        end

        context 'using line separators' do
            
            let :socket_path do
                "#{TEST_LOGS_PATH}/test_socket2"
            end
                        
            let(:my_connection) do
                Class.new(EventMachine::GServer::Listeners::Connection) do
                    
                    def do_work(req)
                        req
                    end
                    
                end
            end
            
            let :opts do
                listener = EventMachine::GServer::Listeners::UnixListener.new(
                    template_opts.merge(socket_path: socket_path, handler: my_connection)
                )
                { listeners: [ listener ] }
            end
            
            context 'message arriving in several pieces' do
                it 'must properly build the request before processing it' do
                    s = server(opts)
                    t = start_server(s)
                    c = client(socket_path: socket_path, no_msg_separator: true)
                    
                    3.times do
                        msg_arr.each do |msg|
                            read_response = msg == separator ? true : false
                            resp = c.send_msg(msg, read_response)
                            if read_response
                                expect(resp).to eq msg_arr.join
                            else
                                expect(resp).to be nil
                            end
                        end
                    end

                    stop_server(s, t)
                end
            end
            context 'client and server with different line separators' do
            
                let :socket_path do
                    "#{TEST_LOGS_PATH}/test_socket3"
                end
                
                let :separator do
                    '?'
                end
                
                it 'should keep waiting for the proper separator before processing it' do
                    s = server(opts)
                    t = start_server(s)
                    c = client(socket_path: socket_path, no_msg_separator: true)

                    3.times do
                        msg_arr.each do |msg|
                            read_response = msg == separator ? true : false
                            if read_response
                                expect {
                                    c.send_msg(msg, read_response)
                                }.to raise_error(Timeout::Error)
                            else
                                expect(c.send_msg(msg, read_response)).to be nil
                            end
                        end
                    end

                    stop_server(s, t)
                end
            end
        end
    end
    describe 'stopping' do

        let :socket_path do
            "#{TEST_LOGS_PATH}/test_socket4"
        end
        
        it 'must not accept new connections, close all open ones and delete socket file' do
            l = described_class.new(template_opts.merge(socket_path: socket_path))
            s = server( listeners: [l] )
            
            t = start_server(s)
            expect(File.exists?(socket_path)).to be true
            c = client(socket_path: socket_path)
            expect(c.send_msg('xxx')).to eq "OK"+EventMachine::GServer::CRLF
            expect(c.connected?).to be true
            expect(s.status).to eq EventMachine::GServer::RUNNING_SYM
            
            stop_server(s, t)
            expect(File.exists?(socket_path)).to be false
        end
    end
    
end