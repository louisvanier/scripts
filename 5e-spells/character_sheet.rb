class CharacterSheet
    ALLOWED_SPELL_SOURCES = ['xphb', 'xge', 'tce', 'dsotdq']

    attr_accessor :char_name, :player_name, :klass_levels, :str, :dex, :con, :int, :wis, :cha, :learned_spells

    #klass levels is an array of ClassLevel representing the source (version) of the class, its level, and any choices made (feats, options, etc)
    def initialize(**args)
        @char_name = args[:char_name]
        @player_name = args[:player_name]
        @klass_levels = args[:klass_levels]
        @str = args[:str]
        @dex = args[:dex]
        @con = args[:con]
        @int = args[:int]
        @wis = args[:wis]
        @cha = args[:cha]
        @data_provider = args[:provider]
        @source = args[:source]
        @learned_spells = args[:learned_spells]
    end

    def spellbooks(refresh = false)
        if !defined?(@spellbooks) || refresh
            @spellbooks = {}
            @klass_levels.each do |kl|
                #sources should be made dynamic
                max_spell_level = (kl.level/2.0).ceil #TODO => can this be read from the tables instead?
                @spellbooks[kl.character_class] = Spellbook.send("for_#{kl.character_class}", provider: @data_provider, subclass: kl.subclass, sources: ALLOWED_SPELL_SOURCES, levels: (1..(max_spell_level)).to_a, caster_level: kl.level)
            end
        end
        @spellbooks
    end

    def spellbook(klass)
        spellbooks(false)[klass]
    end

    def klass_abilities(refresh = false)
        if !defined?(@klass_abilities) || refresh
            @klass_abilities = @klass_levels.map do |klass|
                [klass.character_class, CharacterClass.send(klass.character_class, provider: @data_provider, source: klass.source || "XPHB").all_features(1..klass.level, klass.subclass)]
            end.to_h
        end
        @klass_abilities
    end

    def abilities(refresh = false)
        klass_abilities.map { |klass, abilities| abilities}.flatten
    end

    def spellcaster?
        return abilities.any? { |a| a.name.downcase == "spellcasting"}
    end

    def bonus_actions
        abilities.find_all(&:bonus_action)
    end

    def reactions
        abilities.find_all(&:reaction)
    end

    def print_summary(include_spellbook_summary = true)
        puts "#{char_name} (#{player_name}), #{klass_levels.map{ |kl| kl.to_summary}.join(', ')}"
        puts "--- Abilities"
        puts abilities.map(&:name).join(', ')
        puts "--- Bonus Actions"
        puts bonus_actions.map(&:name).join(', ')
        puts "--- Reactions"
        puts reactions.map(&:name).join(', ')
        puts "--- Conditions and variants"
        conditions_and_variants = Hash.new { |hash, type| hash[type] = Hash.new { |nested, data| nested[data] = [] }}
        abilities.each do |ability|
            ability.rules_map.each do |type, data|
                data.each do |data_value, abilities|
                    conditions_and_variants[type][data_value] << abilities
                    conditions_and_variants[type][data_value].flatten
                end
            end
        end
        pp "condition and other rules -------------"
        conditions_and_variants.each do |type, data|
            pp "  #{type}"
            data.each do |data_val, spells|
                pp "    #{data_val} : #{spells.join(', ')}"
            end
        end
        
        if spellcaster?
            puts "--- Spellbooks"
            klass_levels.each do |kl|
                next unless klass_abilities[kl.character_class].any? { |a| a.name.downcase == "spellcasting"}
                puts "   --- For #{kl.character_class}"
                spells = spellbook(kl.character_class).spells
                spellbook(kl.character_class).print_spellbook_stats
            end
        end
    end
end
