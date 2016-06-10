require 'spec_helper'

describe EventMachine::GServer::Base do
    describe 'initialization' do
        it 'must initialize internal variables and options properly' do
            server = subject
            expect(server.logger).to be nil
            expect(server.stop_timeout).to eq described_class::DEFAULT_STOP_TIMEOUT
            expect(server.listeners). to eq []
            expect(server.stopping).to be false
        end
    end
    describe 'error handler' do
        context 'exception thrown on the server' do
            it 'xxx' do
            end
        end
        context 'exception raised on the connection processing' do
            it 'xxx' do
            end
        end
    end
    describe 'trap signals handling' do
    end
    describe 'starting' do
        context 'with invalid listeners specified' do
            it 'must raise XXX' do
            end
        end
        context 'with no listeners specified' do
            it 'must do its periodic work' do
            end
        end
        context 'with valid listeners specified' do
            it 'must start all listeners' do
            end
            it 'must serve new connections' do
            end
        end
    end
    describe 'stopping' do
        it 'must not accept new connections' do
        end
        context 'with no listener running' do
            it 'must stop' do
            end
        end
        context 'with listeners running' do
            it 'must stop all listeners before stopping' do
            end
        end
        context 'with open client connections ongoing' do
            it 'must wait for up to a timeout for the connections to close before forcing the listeners to stop' do
            end
        end
            
    end
    describe 'request processing' do
        context 'no line separator' do
            it 'xxx' do
            end
        end
        context 'client and server with different line separators' do
            it 'xxx' do
            end
        end
    end
end