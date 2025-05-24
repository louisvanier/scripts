require './spell.rb'

class Spellbook
  attr_reader :referenced_rules

  def initialize(data_provider, caster_levels = { sorcerer: 1, wizard: 1, cleric: 1, paladin: 1, ranger: 1, bard: 1 }, spell_selection = nil, sources = ['xphb'])
    @spell_selection = spell_selection&.map { |name| normalize(name) }
    @caster_levels = caster_levels
    @referenced_rules = {}
    @spell_sources = sources
    @data_provider = data_provider
  end

  def spells
    if !defined?(@spells)
        @spells = @spell_sources.map do |source|
            source_spells = []
            @data_provider.get_spell_source(source).load_spells(@spell_selection, @caster_levels) { |s| source_spells << s }
            source_spells
        end.flatten
    end
    @spells
  end

  def normalize(str)
    str.strip.downcase.gsub(/\s+/, ' ')
  end

#   rules_found = description&.match(/{(@[^{]+)}/)&.captures
#             rules_found&.filter { |r| r.include?("|") }&.each do |r|
#                 pp r
#                 referenced_rules[r.split("|")[0]] ||= []
#                 referenced_rules[r.split("|")[0]] << data["name"]
end


