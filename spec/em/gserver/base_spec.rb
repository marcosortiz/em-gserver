require 'spec_helper'

describe EventMachine::GServer::Base do

    def wait_for_status(server, status, timeout = 3)
        t0 = Time.now
        while server.status != status
            msg = "Server status never changed to #{status} in #{timeout} seconds."
            fail msg if Time.now-t0 > timeout
            sleep 0.01
        end
    end
    
    def start_server(s)
        t = Thread.new { s.run }
        wait_for_status(s, EventMachine::GServer::RUNNING_SYM)
        t.join(0.01)
        t
    end
    
    def stop_server(server, thread)
        server.stop(true)
        thread.join
        wait_for_status(server, EventMachine::GServer::STOPPED_SYM)
    end
    
    let :template_opts do
        logger = Logger.new("#{TEST_LOGS_PATH}/my_server.log")
        { 
            :logger => logger,
        }
    end
    
    def server(name, opts={})
        my_server.new(name, template_opts.merge(opts))
    end
    
    def client(opts={})
        default_opts = {
            :host => '127.0.0.1',
            :port => EventMachine::GServer::DEFAULT_PORT,
            :timeout => 0.1,
            :logger => Logger.new("#{TEST_LOGS_PATH}/my_client.log"),
        }
        EasySockets::TcpSocket.new(default_opts.merge(opts))
    end
    
    let(:my_server) do
        Class.new(described_class) do

            def do_work
            end
        end
    end
    
    let :name do
        'my_test_server'
    end
    
    describe 'initialization' do
        it 'must initialize internal variables and options properly' do
            server = described_class.new(name)
            expect(server.logger).to be nil
            expect(server.stop_timeout).to eq described_class::DEFAULT_STOP_TIMEOUT
            expect(server.listeners). to eq []
            expect(server.stopping).to be false
            expect(server.status).to eq EventMachine::GServer::STOPPED_SYM
        end
    end
    describe 'error handling' do
        context 'exception raised on reactor do_work' do
            
            let :error_msg do
                'reactor do work error!'
            end
            
            let(:my_server) do
                Class.new(described_class) do
                    
                    def do_work
                        EventMachine.add_periodic_timer(0.1) do
                            fail 'reactor do work error!'
                        end
                    end
                end
            end
            
            let(:my_connection) do
                Class.new(EventMachine::GServer::Listeners::Connection) do
                    
                    def do_work(req)
                        req
                    end
                    
                end
            end
            
            let :port do
                EventMachine::GServer::DEFAULT_PORT + 1
            end
            
            let :opts do
                listener = EventMachine::GServer::Listeners::TcpListener.new(
                    template_opts.merge(
                        port: port,
                        handler: my_connection
                    )
                )
                {
                    :listeners => [ listener ]
                }
            end
            
            let :msg do
                "bla\r\n"
            end
            
            it 'must not accept new connections, force all current connections to be closed, raise the exception and stop' do
                s = server(name, opts)
                c = client(port: port)
                t = start_server(s)
                
                # 1. Server is running, with an active connection
                expect(c.send_msg(msg)).to eq msg
                expect(c.connected?).to be true
                expect(s.listeners.first.connections.count).to eq 1
                
                # 2. When it crashes, it must raise the exception, close all
                # connections and stop itself.
                expect {
                    t.join
                }.to raise_error(RuntimeError, error_msg)
                expect(s.listeners.first.connections.count).to eq 0
                expect(s.status).to eq EventMachine::GServer::STOPPED_SYM
                
                
                # 3. Since the server is stopped, no new connections can be
                # stablished.
                3.times do
                    expect {
                        client.connect
                    }.to raise_error(Errno::ECONNREFUSED, /Connection refused/)
                end

                # 4.Clients that were disconnected on step 2 above, figure it
                # out as soon as they try to read/write a new msg.
                expect {
                    c.send_msg(msg)
                }.to raise_error(EOFError)
                expect(c.connected?).to be false
            end
        end
        context 'exception raised on the connection processing' do
            
            let(:my_connection) do
                Class.new(EventMachine::GServer::Listeners::Connection) do
                    
                    def do_work(req)
                        fail req
                    end
                    
                end
            end
            
            let :port do
                EventMachine::GServer::DEFAULT_PORT + 2
            end
            
            let :opts do
                listener = EventMachine::GServer::Listeners::TcpListener.new(
                    template_opts.merge(port: port, :handler => my_connection)
                )
                { :listeners => [ listener ] }
            end
            
            let :msg do
                "bla\r\n"
            end
            
            it 'must close the current connection, keep running and accepting new connections' do
                s = server(name, opts)
                t = start_server(s)
                
                c = client(port: port)
                3.times do
                    expect(c.send_msg(msg)).to eq("#{s.listeners.first.default_error_resp}#{EventMachine::GServer::CRLF}")
                    expect(c.connected?).to be true
                    expect(s.listeners.first.connections.count).to eq 1
                    expect(s.status).to eq(EventMachine::GServer::RUNNING_SYM)
                end
                c.disconnect
                stop_server(s, t)
            end
        end
    end
    describe 'starting' do
        
        it 'must be idempotent'  do
            s = server(name)
            expect(s.status).to eq EventMachine::GServer::STOPPED_SYM
            t = start_server(s)
            3.times do |i|
                expect(s.run).to eq EventMachine::GServer::RUNNING_SYM
            end
            stop_server(s, t)
            expect(s.stop).to eq EventMachine::GServer::STOPPED_SYM
        end
        context 'with invalid listeners specified' do
            
            let :opts do
                listener = 'String is not a valid listener'
                {
                    :listeners => [ listener ]
                }
            end
            
            it 'must raise EventMachine::GServer::InvalidListener' do
                expect{
                    s = server(name, opts)
                }.to raise_error(EventMachine::GServer::InvalidListener)
            end
        end
        context 'with no listeners specified' do

            let :opts do
                { listeners: [] }
            end

            let :count do
                10
            end

            let(:my_server) do
                Class.new(described_class) do
                    attr_reader :count

                    def initialize(name, opts={})
                        @count = 0
                        super(name, opts)
                    end

                    def do_work
                        loop do
                            @count += 1
                            break if @count >= 10
                        end
                    end
                end
            end

            it 'must call do_work' do
                s = server(name, opts)
                expect(s.status).to eq EventMachine::GServer::STOPPED_SYM
                expect(s.count).to eq 0

                t = start_server(s)
                expect(s.status).to eq EventMachine::GServer::RUNNING_SYM
                expect(s.count).to eq count
                stop_server(s, t)
            end
        end
        context 'with valid listeners specified' do
            
            let :count do
                3
            end
            
            let :port0 do
                EventMachine::GServer::DEFAULT_PORT + 3
            end
            
            let :opts do
                arr = []
                count.times do |i|
                    l = EventMachine::GServer::Listeners::TcpListener.new(
                        template_opts.merge(port: port0+i)
                    )
                    arr << l
                    
                end
                { listeners: arr }
            end
            
            def check_listeners(server, status)
                server.listeners.each do |l|
                    expect(l.status).to eq status
                end
            end
            
            it 'must start all listeners' do
                s = server(name, opts)
                expect(s.listeners.count).to eq count
                expect(s.status).to eq EventMachine::GServer::STOPPED_SYM
                check_listeners(s, EventMachine::GServer::STOPPED_SYM)
                
                t = start_server(s)
                expect(s.status).to eq EventMachine::GServer::RUNNING_SYM
                check_listeners(s, EventMachine::GServer::RUNNING_SYM)
                stop_server(s, t)
            end
        end
    end
    describe 'stopping' do
        it 'must be idempotent' do
            s = server(name)
            expect(s.status).to eq EventMachine::GServer::STOPPED_SYM
            3.times do |i|
                expect(s.stop(true)).to eq EventMachine::GServer::STOPPED_SYM
            end
            
            t = start_server(s)
            
            stop_server(s, t)
            3.times do |i|
                expect(s.stop(true)).to eq EventMachine::GServer::STOPPED_SYM
            end
        end
    end
end