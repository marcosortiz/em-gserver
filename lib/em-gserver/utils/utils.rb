module EventMachine
    module GServer
        module Utils
            
            def log(level, msg)
                logger.send(level.to_sym, msg) unless logger.nil?
            end
            
        end
    end
end