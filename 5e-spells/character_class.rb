class CharacterClass
    CLASSES = ['artificer', 'bard', 'barbarian', 'cleric', 'druid', 'fighter', 'monk', 'paladin', 'ranger', 'rogue', 'sorcerer', 'wizard'].freeze
	ATTRIBUTES_EMOJI_MAP = {
		'strength' => '💪',
		'dexterity' => '🐈',
		'constitution' => '🐻',
		'intelligence' => '🧙‍♂️',
		'wisdom' => '⌛',
		'charisma' => '🧲',
	}

	class << self
		CharacterClass::CLASSES.each do |cls|
			define_method("#{cls}".to_sym) do |**args|
				Scraper.logger.info "CharacterClass.#{cls} #{args.keys}"
				return CharacterClass.new(args[:provider], cls, args[:source])
			end
		end

		def attributes_to_emoji_map
			💪
		end
	end

    attr_accessor :primary_attribute, :hit_die_size, :saves_proficiency, :spellcasting_ability, :caster_progression,
        :prepared_spells_change, :class_features, :conditions_and_variants

    def initialize(data_provider, character_class, class_source = nil)
        @character_class = character_class
		@data_provider = data_provider

        @class_details = data_provider.get_character_class(character_class)["class"].find { |klass| klass["source"] == class_source }
		# artificer is giving us troubles here
		if @class_details.nil? && data_provider.get_character_class(character_class)["class"].size == 1
			@class_details = data_provider.get_character_class(character_class)["class"][0]
		end
        @primary_attribute = @class_details["primaryAbility"][0].keys[0]
        @hit_die_size = @class_details["hd"]["faces"]
        @saves_proficiency = @class_details["proficiency"]
        @spellcasting_ability = @class_details["spellcastingAbility"]
        @caster_progression = @class_details["casterProgression"]
        @prepared_spells_change = @class_details["preparedSpellsChange"]

		@class_features = []
		@conditions_and_variants = Hash.new { |hash, type| hash[type] = Hash.new { |nested, data| nested[data] = [] }}
		@class_details["classFeatures"].each do |f|
			next unless f.is_a?(String)
			feature_name = f.split('|')[0].downcase
			next if @class_features.any? { |exist| exist.name.downcase == feature_name }
			feature = ClassFeature.new(data_provider.get_character_class(character_class)["classFeature"].find { |f| f["name"].downcase == feature_name}, nil)
			@class_features << feature
		end

		@subclasses = []
		load_subclasses(data_provider.get_character_class(character_class)["subclass"], data_provider.get_character_class(character_class)["subclassFeature"])
		
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
		result += @subclasses.find_all { |s| subclass.nil? || s.name.downcase == subclass.downcase }.map { |s| s.features.find_all { |f| levels.include?(f.level) }}.flatten
		result.sort { |a, b| a.level <=> b.level}
	end

    def load_subclasses(raw_data_subclasses, raw_data_features)
		# remove PHB subclasses that exists in both PHB and XPHB. We can be inefficient here and do nested loops since there not too many permutations
		filtered = raw_data_subclasses.filter { |phb_version| phb_version["classSource"] == "PHB" && raw_data_subclasses.any? {|xphb_version| xphb_version["classSource"] == "XPHB" && xphb_version["name"] == phb_version["name"] }}
		filtered.each do |subclass|
			subclass_specific_data = raw_data_subclasses.find { |raw| raw["name"] == subclass["name"] }
			@subclasses <<  SubKlass.new(subclass_specific_data, raw_data_features)
		end
    end

    def spellbook_is_also_prepared_spells?
        return prepared_spells_change == "level"
    end
end

class SubKlass
	attr_accessor :name, :short_name, :features

	def initialize(subclass_entry, subclasses_features_list)
		@name = subclass_entry["name"]
		@short_name = subclass_entry["shortName"]
		@features = []
		subclass_entry["subclassFeatures"].each do |f|
			feature_name = f.split('|')[0].downcase
			feature_data = subclasses_features_list.find { |f| f["name"].downcase == feature_name }
			feature = ClassFeature.new(feature_data, @name)
			@features << feature
		end
		# this recursive load might well be simplified
		while @features.any? { |f| f.other_features_referenced.any? { |other| !@features.any? { |exist| exist.name == other }} }
			@features.map(&:other_features_referenced).flatten.compact.uniq.find_all { |other| !@features.any? { |exist| exist.name == other }}.each do |unloaded|
				feature_data = subclasses_features_list.find { |f| f["name"].downcase == unloaded.downcase && f["subclassShortName"] == short_name}
				if feature_data.nil?
					feature_data = subclasses_features_list.find { |f| f["name"].downcase == unloaded.downcase}
				end
				feature = ClassFeature.new(feature_data, @name)
				@features << feature
			end
		end
	end
end

# also covers subclass features, its the same
class ClassFeature
	# these rules format can be ignored. :all means we dont care about any of the nested key
	IGNORABLE_RULES = {
		'item' => :all,
		'variant_rule' => ['Short Rest'],
		'5etools' => ['feat'],
		'book' => :all
	}
	attr_accessor :name, :level, :description, :other_features_referenced, :subclass, :bonus_action, :reaction, :action, :subclass_short_name
    def initialize(raw_json, subclass)
        @name = raw_json["name"]
		@subclass_short_name = raw_json["subclassShortName"]
        @level = raw_json["level"].to_i
		@other_features_referenced = []
		@subclass = subclass
		@description = flatten_entries(raw_json["entries"])
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
		map = Hash.new { |hash, type| hash[type] = Hash.new { |nested, data| nested[data] = [] }}
		rules_found = description&.match(/{(@[^{]+)}/)&.captures
		rules_found&.filter { |r| r.include?("|") }&.each do |r|
			type = r.split("|")[0].split(' ')[0].gsub('@', '')
			data = r.split("|")[0].split(' ')[1..-1].join(' ').gsub('@', '')
			next if IGNORABLE_RULES[type] == :all || IGNORABLE_RULES[type]&.include?(data)
			map[type][data] << self.to_short_s
		end
		map
	end

	def flatten_entries(entries)
		return "" unless entries
		entries.map do |entry|
		case entry
		when String then entry
		when Hash
			if entry["type"] == "entries" && entry["name"]
				"**#{entry['name']}**\n" + flatten_entries(entry["entries"])
			elsif entry["type"] == "list"
				entry["items"].map { |i| "- #{i}" }.join("\n")
			elsif entry["type"] == "table"
				([entry["colLabels"].join("|")] + entry["rows"].map { |r| r.join("|")}).join("\n")
			elsif entry["type"] == "refSubclassFeature"
				@other_features_referenced << entry["subclassFeature"].split('|')[0]
				nil
			else
				nil
			end
		else nil
		end
		end.compact.join("\n\n")
	end

	def to_short_s
		"#{name} - lvl #{level}#{ subclass.nil? ? "" : " - #{subclass} subclass feature" }"
	end

	def to_s
		"#{name} - lvl #{level}#{ subclass.nil? ? "" : " - #{subclass} subclass feature" }\n#{description}"
	end
end
