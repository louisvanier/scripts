class ClassLevels
    attr_accessor :character_class, :level, :choices, :source

    def initialize(character_class:, source: "xphb", level: 1, choices: nil)
        @character_class = character_class
        @source = source
        @level = level
        @choices = choices
    end

    def subclass
        return choices[:subclass]
    end

    def to_summary
        result = @character_class
        if !subclass.nil?
            result += " (#{subclass})"
        end
        result += " #{@level}"
    end
end
