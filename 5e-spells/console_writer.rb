class ConsoleWriter
    NESTING_INDENT = 2
    def initialize(initial_nesting = 0)
        if initial_nesting == 0
            @nestings = []
        else
            @nestings = [initial_nesting]
        end
    end

    def with_nesting
        open_nesting
        yield
        close_nesting
    end

    def write(msg)
        if msg.is_a?(String)
            nest_message(msg)
        elsif msg.is_a?(Array)
            msg.each { |m| nest_message(m) }
        end
    end

    def open_nesting
        last_nesting = @nestings.empty? ? 0 : @nestings[-1]
        @nestings << last_nesting + NESTING_INDENT
    end

    def close_nesting
        if @nestings.empty?
            exit("tried to close nesting when none was open")
        end
        @nestings.pop
    end

    def nest_message(message)
        nesting_level = 0
        if !@nestings.empty?
            nesting_level = @nestings[-1]
        end
        puts "#{" " * nesting_level}#{message}"
    end
end
