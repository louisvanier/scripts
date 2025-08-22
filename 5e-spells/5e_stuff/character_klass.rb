class CharacterKlass
  CLASS_LIST = {
    'artificer' => ['alchemist', 'armorer', 'artillerist', 'battle smith'],
    'barbarian' => ['berserker', 'totem warrior', 'battlerager', 'ancestral guardian', 'storm herald', 'zealot', 'beast',
                    'wild magic', 'juggernaut', 'giant', 'wild heart', 'world tree'],
    'bard' => %w[lore valor glamour swords whispers creation eloquence spirits tragedy dance
                   glamour],
    'cleric' => ['knowledge', 'life', 'light', 'nature', 'tempest', 'trickery', 'war', 'death', 'arcana',
                 'ambition (psa)', 'solidarity (psa)', 'strength (psa)', 'zeal (psa)', 'forge', 'grave', 'order', 'peace', 'twilight', 'blood', 'moon'],
    'druid' => %w[land moon dreams shepherd spores stars wildfire blighted sea],
    'fighter' => ['battle master', 'champion', 'eldritch knight', 'purple dragon knight (banneret)', 'arcane archer',
                  'cavalier', 'samurai', 'echo knight', 'psi warrior', 'rune knight'],
    'monk' => ['shadow', 'four elements', 'open hand', 'long death', 'drunken master', 'kensei', 'sun soul', 'mercy',
               'astral self', 'ascendant dragon', 'cobalt soul', 'elements'],
    'paladin' => ['devotion', 'ancients', 'vengeance', 'oathbreaker', 'crown', 'conquest', 'redemption', 'glory',
                  'watchers', 'open sea'],
    'ranger' => ['beast master', 'hunter', 'gloom stalker', 'horizon walker', 'monster slayer', 'fey wanderer',
                 'swarmkeeper', 'drakewarden'],
    'rogue' => ['arcane trickster', 'assassin', 'thief', 'inquisitive', 'mastermind', 'scout', 'swashbuckler', 'phantom',
                'soulknife'],
    'sorcerer' => ['pyromancer (PSK)', 'divine soul', 'shadow', 'storm', 'runechild', 'lunar', 'aberrant', 'clockwork',
                   'draconic', 'wild magic'],
    'warlock' => ['archfey', 'fiend', 'great old one', 'undying', 'celestial', 'hexblade', 'fathomless', 'genie',
                  'undead'],
    'wizard' => ['abjurer', 'conjuration', 'diviner', 'enchantment', 'evoker', 'illusionist', 'necromancy',
                 'transmutation', 'war', 'chronurgy', 'graviturgy', 'bladesinging', 'scribes', 'blood magic']
  }.freeze
  ATTRIBUTES_EMOJI_MAP = {
    'strength' => '💪',
    'dexterity' => '🐈',
    'constitution' => '🐻',
    'intelligence' => '🧙‍♂️',
    'wisdom' => '⌛',
    'charisma' => '🧲'
  }

  class << self
    CharacterKlass::CLASS_LIST.each do |cls, _|
      define_method("#{cls}".to_sym) do |**args|
        Scraper.logger.info "CharacterKlass.#{cls} #{args.keys}"
        klass_source = args[:source] || 'XPHB'
        cache_key = "#{cls}#{klass_source}"
        klass_cache[cache_key] = CharacterKlass.new(cls, klass_source) if klass_cache[cache_key].nil?
        klass_cache[cache_key]
      end
    end

    def subclass_method_name(subclass)
      subclass.gsub(Regexp.union('(psk)', '(psa)', '(', ')'), '').gsub(' ', '_')
    end

    private

    def klass_cache
      @klass_cache = {} unless defined?(@klass_cache)
      @klass_cache
    end
  end

  attr_accessor :primary_attribute, :hit_die_size, :saves_proficiency, :spellcasting_ability, :caster_progression,
                :prepared_spells_change, :class_features, :conditions_and_variants, :character_class, :subclasses, :spell_progression

  def initialize(character_class, class_source = nil)
    @character_class = character_class

    @class_details = Scraper.instance.get_character_class(character_class)['class'].find do |klass|
        klass['source'] == class_source
    end
    # artificer is giving us troubles here
    if @class_details.nil? && Scraper.instance.get_character_class(character_class)['class'].size == 1
      @class_details = Scraper.instance.get_character_class(character_class)['class'][0]
    end
    @primary_attribute = @class_details['primaryAbility'][0].keys[0]
    @hit_die_size = @class_details['hd']['faces']
    @saves_proficiency = @class_details['proficiency']
    @spellcasting_ability = @class_details['spellcastingAbility']
    @caster_progression = @class_details['casterProgression']
    @prepared_spells_change = @class_details['preparedSpellsChange']
    @wizard_like_spells_known = !@class_details['spellsKnownProgressionFixed'].nil?
    spell_table = @class_details['classTableGroups'].find do |group|
  group['title'] == 'Spell Slots per Spell Level'
    end
    @spell_progression = spell_table['rowsSpellProgression'] unless spell_table.nil?

    @class_features = []
    @conditions_and_variants = Hash.new do |hash, type|
  hash[type] = Hash.new do |nested, data|
 nested[data] = []
                                   end
    end
    @class_details['classFeatures'].each do |f|
      next unless f.is_a?(String)

      feature_name = f.split('|')[0].downcase
      next if @class_features.any? { |exist| exist.name.downcase == feature_name }

      feature = KlassFeature.new(Scraper.instance.get_character_class(character_class)['classFeature'].find do |f|
          f['name'].downcase == feature_name
      end, nil)
      @class_features << feature
    end

    @subclasses = []
    load_subclasses(Scraper.instance.get_character_class(character_class)['subclass'],
                    Scraper.instance.get_character_class(character_class)['subclassFeature'])

    @class_features.each do |feature|
      feature.rules_map.each do |type, data|
        data.each do |data_value, abilities|
          @conditions_and_variants[type][data_value] << abilities
          @conditions_and_variants[type][data_value].flatten
        end
      end
    end
    @subclasses.each do |subclass|
      subclass.features.each do |feature|
        feature.rules_map.each do |type, data|
          data.each do |data_value, abilities|
            @conditions_and_variants[type][data_value] << abilities
            @conditions_and_variants[type][data_value].flatten
          end
        end
      end
    end
  end

  # subclass is expected to be downcased
  def all_features(levels = 1...20, subclass = nil)
    result = @class_features.find_all { |f| levels.include?(f.level) }
    result += @subclasses.find_all do |s|
  subclass.nil? || s.name.downcase == subclass.downcase
    end.map do |s|
      s.features.find_all do |f|
     levels.include?(f.level)
      end
    end.flatten
    result.sort { |a, b| a.level <=> b.level }
  end

  def load_subclasses(raw_data_subclasses, raw_data_features)
    # remove PHB subclasses that exists in both PHB and XPHB. We can be inefficient here and do nested loops since there not too many permutations
    filtered = raw_data_subclasses.reject do |phb_version|
      phb_version['classSource'] == 'PHB' && raw_data_subclasses.any? do |xphb_version|
     xphb_version['classSource'] == 'XPHB' && xphb_version['name'] == phb_version['name']
      end
    end
    filtered.each do |subclass|
      subclass_specific_data = raw_data_subclasses.find { |raw| raw['name'] == subclass['name'] }
      @subclasses << SubKlass.new(subclass_specific_data, raw_data_features)
    end
  end

  def subclass(subklass)
    @subclasses.find { |s| s.short_name.downcase == subklass.downcase }
  end

  def spellbook_type
    return :none if @prepared_spells_change.nil?

    if @prepared_spells_change == 'level'
      :prepared_is_known
    else
      @wizard_like_spells_known ? :prepares_from_book : :known_is_entire_list
    end
  end
end

class SubKlass
  attr_accessor :name, :short_name, :features, :spell_progression

  def initialize(subclass_entry, subclasses_features_list)
    @name = subclass_entry['name']
    @short_name = subclass_entry['shortName']
    @features = []
    subclass_entry['subclassFeatures'].each do |f|
      feature_name = f.split('|')[0].downcase
      feature_data = subclasses_features_list.find { |f| f['name'].downcase == feature_name }
      feature = KlassFeature.new(feature_data, @name)
      @features << feature
    end
    # this recursive load might well be simplified
    while @features.any? { |f|
      f.other_features_referenced.any? { |other|
                           !@features.any? { |exist|
    exist.name == other
                           }
      }
    }
      @features.map(&:other_features_referenced).flatten.compact.uniq.find_all do |other|
        !@features.any? do |exist|
      exist.name == other
        end
      end.each do |unloaded|
        feature_data = subclasses_features_list.find do |f|
          f['name'].downcase == unloaded.downcase && f['subclassShortName'] == short_name
        end
        if feature_data.nil?
          feature_data = subclasses_features_list.find { |f| f['name'].downcase == unloaded.downcase }
        end
        feature = KlassFeature.new(feature_data, @name)
        @features << feature
      end
    end

    spell_table = subclass_entry['subclassTableGroups']&.find do |group|
      group['title'] == 'Spell Slots per Spell Level'
    end
    @spell_progression = spell_table['rowsSpellProgression'] unless spell_table.nil?

    @prepared_spells_change = subclass_entry['preparedSpellsChange']
    @wizard_like_spells_known = !subclass_entry['spellsKnownProgressionFixed'].nil?
  end

  def extra_spells(levels = 1..20)
    @features.find_all { |f| !f.extra_spells.empty? }.map do |f|
      f.extra_spells.find_all { |level, _| levels.include?(level) }.map { |_, spells| spells }.flatten
    end.flatten
  end

  def spellbook_type
    if @prepared_spells_change == 'level'
      :prepared_is_known
    else
      @wizard_like_spells_known ? :prepares_from_book : :known_is_entire_list
    end
  end
end

# also covers subclass features, its the same
class KlassFeature
  # these rules format can be ignored. :all means we dont care about any of the nested key
  IGNORABLE_RULES = {
    'item' => :all,
    'variant_rule' => ['Short Rest'],
    '5etools' => ['feat'],
    'book' => :all
  }
  attr_accessor :name, :level, :description, :other_features_referenced, :subclass, :bonus_action, :reaction, :action,
                :subclass_short_name, :extra_spells

  def initialize(raw_json, subclass)
    @name = raw_json['name']
      @subclass_short_name = raw_json['subclassShortName']
      @level = raw_json['level'].to_i
      @other_features_referenced = []
      @extra_spells = Hash.new { |hash, key| hash[key] = [] }
      @subclass = subclass
      @description = flatten_entries(raw_json['entries'])
      @reaction = false
      @bonus_action = false
      @action = false
      if @description =~ /{@variantrule Reaction\|XPHB}/ || @description =~ /use your reaction/
        @reaction = true
      elsif @description =~ /@variantrule Bonus Action\|XPHB}/ || @description =~ /bonus action/
        @bonus_action = true
      end
  end

  # returns a map where the first level of key is the type of variant or rules (i.e. condition)
  # the second level is any option (I.e. feared, entangled, etc)
  # the value is an array of abilities that point to that condition or rule
  def rules_map
    # Ruby's funny hash with default values for uninitialized keys ensures these are new hashes and arrays each time because of the block
    map = Hash.new { |hash, type| hash[type] = Hash.new { |nested, data| nested[data] = [] } }
    rules_found = description&.scan(/{(@[^{]+)}/)&.flatten
    rules_found&.filter { |r| r.include?('|') }&.each do |r|
      type = r.split('|')[0].split(' ')[0].gsub('@', '')
      data = r.split('|')[0].split(' ')[1..-1].join(' ').gsub('@', '')
      next if IGNORABLE_RULES[type] == :all || IGNORABLE_RULES[type]&.include?(data)

      map[type][data] << to_short_s
    end
    map
  end

  def flatten_entries(entries)
    return '' unless entries

    entries.map do |entry|
      case entry
      when String then entry
      when Hash
        if entry['type'] == 'entries' && entry['name']
          "**#{entry['name']}**\n" + flatten_entries(entry['entries'])
        elsif entry['type'] == 'list'
          entry['items'].map { |i| "- #{i}" }.join("\n")
        elsif entry['type'] == 'table'
          extract_extra_spells(entry['rows'])
          ([entry['colLabels'].join('|')] + entry['rows'].map { |r| r.join('|') }).join("\n")
        elsif entry['type'] == 'refSubclassFeature'
          @other_features_referenced << entry['subclassFeature'].split('|')[0]
          nil
        end
      end
    end.compact.join("\n\n")
  end

  def extract_extra_spells(rows)
    rows.each do |by_level|
      level = nil
      spells = []
      by_level.each do |raw|
        next unless raw.is_a?(String)

        level_match = raw.match(/(\d+)(rd|st|th)/)&.captures
        level = level_match[0].to_i unless level_match.nil?
        spell_matches = raw.scan(/{@spell ([^}]+)}/)&.flatten
        spell_matches&.each do |match|
          spells << match.gsub('@spell', '')
        end
      end
      @extra_spells[level] += spells unless level.nil? || spells.compact.empty?
    end
  end

  def to_short_s
    "#{name} - lvl #{level}#{subclass.nil? ? '' : " - #{subclass} subclass feature"}"
  end

  def to_s
    "#{name} - lvl #{level}#{subclass.nil? ? '' : " - #{subclass} subclass feature"}\n#{description}"
  end
end
