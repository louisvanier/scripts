class CharacterSheet
  ALLOWED_SPELL_SOURCES = %w[xphb xge tce dsotdq]

  attr_accessor :char_name, :player_name, :klass_levels, :str, :dex, :con, :int, :wis, :cha

  # klass levels is an array of ClassLevel representing the source (version) of the class, its level, and any choices made (feats, options, etc)
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
    @source = args[:source]
  end

  def url_player_name
    player_name.gsub('.', '').underscore
  end

  def spellbooks(refresh = false)
    if !defined?(@spellbooks) || refresh
      @spellbooks = {}
      @klass_levels.each do |kl|
        # sources should be made dynamic with the constant as a default value
        @spellbooks[kl.character_class] = kl.spellbook
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
        [klass.character_class, klass.abilities]
      end.to_h
    end
    @klass_abilities
  end

  def abilities(_refresh = false)
    klass_abilities.map { |_klass, abilities| abilities }.flatten
  end

  def spellcaster?
    @klass_levels.any?(&:has_spellcasting?)
  end

  def bonus_actions
    abilities.find_all(&:bonus_action)
  end

  def reactions
    abilities.find_all(&:reaction)
  end

  def conditions_and_variants
    conditions_and_variants = Hash.new { |hash, type| hash[type] = Hash.new { |nested, data| nested[data] = [] } }
    abilities.each do |ability|
      ability.rules_map.each do |type, data|
        data.each do |data_value, abilities|
          conditions_and_variants[type][data_value] << abilities
          conditions_and_variants[type][data_value].flatten
        end
      end
    end
    conditions_and_variants
  end

  def spellcasting_klass_levels
    @klass_levels.find_all(&:has_spellcasting?)
  end

  def print_summary(writer = ConsoleWriter.new)
    writer.write "#{char_name} (#{player_name}), #{klass_levels.map { |kl| kl.to_summary }.join(', ')}"
    writer.with_nesting do
      writer.write '--- Class Abilities ---'
      writer.with_nesting do
        writer.write abilities.map(&:name).join(', ')
      end
      writer.write '--- Bonus Actions & Reactions ---'
      writer.with_nesting do
        writer.write "  Bonus: #{bonus_actions.map(&:name).join(', ')} | Reaction: #{reactions.map(&:name).join(', ')}"
      end
      writer.write '--- condition and other rules ---'
      writer.with_nesting do
        conditions_and_variants.each do |type, data|
          writer.write "#{type}"
          writer.with_nesting do
            data.each do |data_val, spells|
              writer.write "#{data_val} : #{spells.join(', ')}"
            end
          end
        end
      end
      if spellcaster?
        writer.write '--- Spellbooks ---'
        writer.with_nesting do
          klass_levels.each do |kl|
            next unless klass_abilities[kl.character_class].any? { |a| a.name.downcase == 'spellcasting' }

            writer.with_nesting do
              writer.write "--- For #{kl.klass_name} --- [#{spellbook(kl.character_class).spellbook_legend}]"
              writer.with_nesting do
                spellbook(kl.character_class).print_spellbook_stats(writer)
                # spellbook(kl.character_class).compact_list.each do |l|
                # writer.write '^^^^^^^'
                # writer.write l.to_compact_list
                # writer.write l.to_compact_list_line_two
                # end
              end
            end
          end
        end
      end
    end
  end
end
