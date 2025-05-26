require './spell.rb'
require './spell_list.rb'
require './character_class.rb'

class Spellbook
  attr_reader :conditions_and_variants, :damage_types, :saves

  class << self
    # CharacterClass::CLASSES.each do |cls|
    #     define_method("list_for_#{cls}".to_sym) do |**args|
    #         pp "Spellbook.list_for_#{cls} #{args}"
    #         spells = SpellList.send("list_for_#{cls}", provider: args[:provider], sources: args[:sources])
    #         return SpellList.new(args[:provider], cls, args[:subclass], args[:sources])
    #     end
    # end

    CharacterClass::CLASSES.each do |cls|
        define_method("for_#{cls}".to_sym) do |**args|
            pp "Spellbook.for_#{cls} #{args}"
            spells = SpellList.send("list_for_#{cls}", provider: args[:provider], sources: args[:sources], subclass: args[:subclass]).get_spell_list
            return Spellbook.new(args[:provider], { cls.to_sym => args[:caster_level] }, args[:levels], spells, args[:sources])
        end
    end
  end

  def initialize(data_provider, caster_levels = { sorcerer: 1, wizard: 1, cleric: 1, paladin: 1, ranger: 1, bard: 1 }, levels = nil, spell_selection = nil, sources = ['xphb'])
    @spell_selection = spell_selection&.map { |name| normalize(name) }
    @caster_levels = caster_levels
    @conditions_and_variants = {}
    @damage_types = {}
    @saves = {}
    @spell_sources = sources
    @data_provider = data_provider
    @spell_levels = levels
  end

  def spells
    if !defined?(@spells)
        @spells = []
        @spell_sources.map do |source|
            @data_provider.get_spell_source(source)&.load_spells(@spell_selection, @caster_levels, @spell_levels) do |spell|
                @spells << spell
                scan_for_rules(spell)
            end
        end.compact
        @spells.sort! { |a, b| a.level <=> b.level }
    end
    @spells
  end

  def print_spellbook_stats
    pp "condition and other rules -------------"
    pp conditions_and_variants
    pp "damage types -------------"
    pp damage_types
    pp "saves targeted -------------"
    pp saves
    pp "bonus action spells -------------"
    bonus_actions.each { |s| puts s.to_summary }
    pp "reaction spells -------------"
    reactions.each { |s| puts s.to_summary }
  end

  def bonus_actions
    spells.filter { |s| s.casting_time =~ /bonus/}
  end

  def reactions
    spells.filter { |s| s.casting_time =~ /reaction/}
  end

  def normalize(str)
    str.strip.downcase.gsub(/\s+/, ' ')
  end

  def scan_for_rules(spell)
    rules_found = spell.description&.match(/{(@[^{]+)}/)&.captures
    rules_found&.filter { |r| r.include?("|") }&.each do |r|
        type = r.split("|")[0].split(' ')[0]
        data = r.split("|")[0].split(' ')[1..-1].join(' ')
        conditions_and_variants[type] ||= {}
        conditions_and_variants[type][data] ||= []
        conditions_and_variants[type][data] << spell.to_summary
    end

    spell.damage_types&.each do |dmg|
        damage_types[dmg] ||= []
        damage_types[dmg] << spell.to_summary
    end

    spell.saving_throws&.each do |save|
        saves[save] ||= []
        saves[save] << spell.to_summary
    end
  end
end


