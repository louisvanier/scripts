require './spell.rb'
require './spell_list.rb'
require './character_class.rb'

class Spellbook
  attr_accessor :conditions_and_variants, :damage_types, :saves

  DAMAGE_TYPES_EMOJI_MAP = {
        "lightning" => '⚡',
        "radiant" => '🔆',
        "acid" => '🍋‍🟩',
        "cold" => '❄️',
        "necrotic" => '☠️',
        "thunder" => '〰️',
        "fire" => '🔥',
        "psychic" => '🤯',
        'piercing' => '🔪',
        'slashing' => '🪓',
        'bludgeoning' => '⚒️',
        'force' => '🪄',
        "poison" => '🤢'
      }

  class << self
    CharacterClass::CLASSES.each do |cls|
        define_method("for_#{cls}".to_sym) do |**args|
            spells = SpellList.send("list_for_#{cls}", provider: args[:provider], sources: args[:sources], subclass: args[:subclass]).get_spell_list
            return Spellbook.new(args[:provider], { cls.to_sym => args[:caster_level] }, args[:levels], spells, args[:sources])
        end
    end
  end

  def initialize(data_provider, class_levels = { sorcerer: 1, wizard: 1, cleric: 1, paladin: 1, ranger: 1, bard: 1 }, levels = nil, spell_selection = nil, sources = ['xphb'])
    @spell_selection = spell_selection&.map { |name| normalize(name) }
    @class_levels = class_levels
    @conditions_and_variants = {}
    @damage_types = Hash.new { |h, k| h[k] = [] } 
    @saves = Hash.new { |h, k| h[k] = [] } 
    @spell_sources = sources
    @data_provider = data_provider
    @spell_levels = levels
  end

  def spells(refresh = false)
    if !defined?(@spells) || refresh
        @spells = []
        @spell_sources.map do |source|
            @data_provider.get_spell_source(source)&.load_spells(@spell_selection, @class_levels, @spell_levels) do |spell|
                @spells << spell
                scan_for_rules(spell)
            end
        end.compact
        compact_damage_types
        @spells.sort! { |a, b| a.level <=> b.level }
    end
    @spells
  end

  def spellbook_legend
    legend = []
    if spells.any?(&:scales_at_higher_level?)
      legend << "* => Scales at higher level"
    end

    if spells.any?(&:requires_concentration?)
      legend <<  "(C) => Requires Concentration"
    end

    legend.join(', ')
  end

  def print_spellbook_stats(writer = ConsoleWriter.new)
    writer.write "--- condition and other rules ---"
    conditions_and_variants.each do |type, data|
      writer.open_nesting
      writer.write "#{type}"
      writer.open_nesting
      data.each do |data_val, spells|
        writer.write "#{data_val} : #{spells.sort.map(&:to_short_summary).join(', ')}"
      end
      writer.close_nesting
      writer.close_nesting
    end
    print_summary_damage_types(writer)
    print_summary_saves(writer)
    writer.write "--- bonus action spells, total #{bonus_actions.size} ---"
    writer.open_nesting
    writer.write bonus_actions.map(&:to_short_summary).join(', ')
    writer.close_nesting
    writer.write "--- reaction spells, total #{reactions.size} ---"
    writer.open_nesting
    writer.write reactions.map(&:to_short_summary).join(', ')
    writer.close_nesting
  end

  def print_summary_damage_types(writer = ConsoleWriter.new)
    reverse_emoji_lookup = Spellbook::DAMAGE_TYPES_EMOJI_MAP.invert
    legend = damage_types.map { |t, s| t.split(' / ') }.flatten.uniq.sort.map { |t| reverse_emoji_lookup[t].nil? ? t : "#{t} => #{reverse_emoji_lookup[t]}" }.join(', ')
    writer.write "--- damage types --- [#{legend}]"
    damage_types.each do |type, spells|
      writer.open_nesting
      writer.write "  #{type}"
      writer.write "    #{spells.sort.map(&:to_short_summary).join(', ')}"
      writer.close_nesting
    end
  end

  def print_summary_saves(writer = ConsoleWriter.new)
    reverse_emoji_lookup = CharacterClass::ATTRIBUTES_EMOJI_MAP.invert
    legend = saves.map { |t, s| t.split(' ') }.flatten.uniq.sort.map { |t| reverse_emoji_lookup[t].nil? ? t : "#{t} => #{reverse_emoji_lookup[t]}" }.join(', ')
    writer.write "--- Saves targeted --- [#{legend}]"
    saves.each do |type, spells|
      writer.open_nesting
      writer.write "  #{type}"
      writer.write "    #{spells.sort.map(&:to_short_summary).join(', ')}"
      writer.close_nesting
    end
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
        type = r.split("|")[0].split(' ')[0].gsub('@', '')
			  data = r.split("|")[0].split(' ')[1..-1].join(' ').gsub('@', '')
        conditions_and_variants[type] ||= {}
        conditions_and_variants[type][data] ||= []
        conditions_and_variants[type][data] << spell
    end

    spell.damage_types&.each do |dmg|
      mapped_type = Spellbook::DAMAGE_TYPES_EMOJI_MAP[dmg] || dmg
      @damage_types[mapped_type] << spell
    end

    spell.saving_throws&.each do |save|
      mapped_type = CharacterClass::ATTRIBUTES_EMOJI_MAP[save]
      @saves[mapped_type] << spell
    end
  end

  def compact_damage_types
    dupes = []
    damage_types.each do |type, spells|
      next if dupes.any? { |d| d.include?(type) }
      matches = damage_types.find_all { |other_type, other_spells| other_type != type && !dupes.include?(other_type) && other_spells.sort == spells.sort }.map { |t, s| t }
      matches << type unless matches.empty?
      dupes << matches unless matches.empty?
    end
    dupes.each do |dupe|
      damage_types[dupe.join(' / ')] = damage_types[dupe[0]]
      dupe.each do |damage_type|
        damage_types.reject! { |t, s| t == damage_type}
      end
    end
  end

  
end


