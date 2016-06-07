module EventMachine
    module GServer
        CR           = "\r"
        LF           = "\n"
        CRLF         = CR + LF
        CHUNK_SIZE   = 1024 * 16
        DEFAULT_HOST = '0.0.0.0'
        DEFAULT_PORT = 2000
        DEFAULT_SOCKET_PATH = '/tmp/test_socket'
    
        STOPPED_SYM      = :stopped
        RUNNING_SYM      = :running
        LISTENERS_SYM    = :listeners
        STOP_TIMEOUT_SYM = :stop_timeout
    end
end