class CharacterKlassLevel
  attr_accessor :character_class, :level, :choices, :source

  class << self
    CharacterKlass::CLASS_LIST.each do |cls, subklasses|
      define_method("#{cls}".to_sym) do |**args|
        Scraper.logger.info "CharacterKlassLevel.#{cls} #{args.keys}"
        CharacterKlassLevel.new(character_class: CharacterKlass.send(cls), source: 'XPHB',
                                level: args[:level] || 1)
      end

      subklasses.each do |subklass|
        define_method("#{cls}_#{CharacterKlass.subclass_method_name(subklass)}".to_sym) do |**args|
          Scraper.logger.info "CharacterKlassLevel.#{cls}_#{CharacterKlass.subclass_method_name(subklass)} #{args.keys}"
          choices = (args[:choices] || {}).merge({ subclass: subklass })
          CharacterKlassLevel.new(character_class: CharacterKlass.send(cls),
                                  source: args[:source] || 'XPHB', level: args[:level] || 1, choices: choices)
        end
      end
    end
  end

  def initialize(character_class:, source: 'XPHB', level: 1, choices: nil)
    @character_class = character_class
    @source = source
    @level = level
    @choices = choices
  end

  def subclass
    @character_class.subclass(choices[:subclass])
  end

  def learned_spells
    [@choices[:spells], subclass.extra_spells(1..@level)].flatten.compact
  end

  def klass_name
    @character_class.character_class
  end

  def abilities
    @abilities = @character_class.all_features(1..@level, subclass&.short_name) unless defined?(@abilities)
    @abilities
  end

  def has_spellcasting?
    abilities.any? { |a| a.name.downcase == 'spellcasting' }
  end

  def to_summary
    result = klass_name
    result += " (#{subclass.name})" unless subclass.nil?
    result + " #{@level}"
  end

  def spellbook
    book_type = @character_class.spellbook_type
    book_type = subclass.spellbook_type if book_type == :none
    case book_type
    when :known_is_entire_list
      spells = SpellList.send("list_for_#{klass_name}", sources: [@source] || ['XPHB'],
                                                        subclass: subclass.short_name).get_spell_list
      Spellbook.new({ klass_name.to_sym => @level }, (1..(max_spell_level)).to_a, spells,
                    CharacterSheet::ALLOWED_SPELL_SOURCES)
    else
      Spellbook.new({ klass_name.to_sym => @level }, (1..(max_spell_level)).to_a, learned_spells,
                    CharacterSheet::ALLOWED_SPELL_SOURCES)
    end
  end

  def max_spell_level
    unless @character_class.spell_progression.empty?
      return @character_class.spell_progression[@level - 1].count do |slots|
        slots > 0
      end
    end
    unless subclass.spell_progression.empty?
      return subclass.spell_progression[@level - 1].count do |slots|
        slots > 0
      end
    end

    1
  end
end
