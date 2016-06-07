module EventMachine
    module GServer
        module Utils
        
            def log(level, msg)
                logger.send(level, msg) unless logger.nil?
            end
        end
    end
end