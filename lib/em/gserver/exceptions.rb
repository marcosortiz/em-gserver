module EventMachine
    module GServer
        
        #
        # @author Marcos Ortiz
        # Raised by {EventMachine::GServer::Base} when using an invalid
        # listener class.
        #
        class InvalidListener < StandardError
        end
        
        #
        # @author Marcos Ortiz
        # Raised by {EventMachine::GServer::Base} when using an invalid
        # handler class.
        #
        class InvalidHandlerClass < StandardError
        end
    end
end