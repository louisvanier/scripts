class CharacterClass
    CLASSES = ['artificer', 'bard', 'barbarian', 'cleric', 'druid', 'fighter', 'monk', 'paladin', 'ranger', 'rogue', 'sorcerer', 'wizard'].freeze

	class << self
		CharacterClass::CLASSES.each do |cls|
			define_method("#{cls}".to_sym) do |**args|
				pp "CharacterClass.#{cls} #{args.keys}"
				return CharacterClass.new(args[:provider], cls)
			end
		end
	end

    attr_accessor :primary_attribute, :hit_die_size, :saves_proficiency, :spellcasting_ability, :caster_progression,
        :prepared_spells_change, :features

    def initialize(data_provider, character_class)
        @character_class = character_class

        @class_details = data_provider.get_character_class(character_class)["class"][0]
		if @class_details["source"] == "PHB" && data_provider.get_character_class(character_class)["class"].size > 1 && data_provider.get_character_class(character_class)["class"][1]["source"] == "XPHB"
			@class_details = data_provider.get_character_class(character_class)["class"][1]
		end
        @primary_attribute = @class_details["primaryAbility"][0].keys[0]
        @hit_die_size = @class_details["hd"]["faces"]
        @saves_proficiency = @class_details["proficiency"]
        @spellcasting_ability = @class_details["spellcastingAbility"]
        @caster_progression = @class_details["casterProgression"]
        @prepared_spells_change = @class_details["preparedSpellsChange"]

		all_features = data_provider.get_character_class(character_class)["classFeature"]
		filtered_features = all_features.filter { |phb_version| phb_version["classSource"] == "PHB" && all_features.any? {|xphb_version| xphb_version["classSource"] == "XPHB" && xphb_version["name"] == phb_version["name"] }}
        @features = filtered_features.map { |f| ClassFeature.new(f, nil) }

		@subclasses = {}
		load_subclasses(data_provider.get_character_class(character_class)["subclass"], data_provider.get_character_class(character_class)["subclassFeature"])

    end

	# subclass is expected to be downcased
	def all_features(levels = 1...20, subclass = nil)
		result = @features.find_all { |f| levels.include?(f.level) }
		result += @subclasses.find_all { |s, f| subclass.nil? || s.downcase == subclass }.map { |s, all_features| all_features.find_all { |f| levels.include?(f.level) }}.flatten
		result.sort { |a, b| a.level <=> b.level}
	end

    def load_subclasses(raw_data_subclasses, raw_data_features)
		
		# remove PHB subclasses that exists in both PHB and XPHB. We can be inefficient here and do nested loops since there not too many permutations
		filtered = raw_data_subclasses.filter { |phb_version| phb_version["classSource"] == "PHB" && raw_data_subclasses.any? {|xphb_version| xphb_version["classSource"] == "XPHB" && xphb_version["name"] == phb_version["name"] }}
		filtered.each do |subclass|
			@subclasses[subclass["name"]] = []
			subclass["subclassFeatures"].each do |f|
				feature_name = f.split('|')[0].downcase
				feature_data = raw_data_features.find { |f| f["name"].downcase == feature_name }
				feature = ClassFeature.new(feature_data, subclass["name"])
				feature.other_features_referenced.each do |other|
					feature_data = raw_data_features.find { |f| f["name"].downcase == other.downcase }
					other = ClassFeature.new(feature_data, subclass["name"])
					@subclasses[subclass["name"]] << other
				end
				@subclasses[subclass["name"]] << feature
			end

		end
    end

    def known_spells_is_prepared?
        return prepared_spells_change == "level"
    end
end

# also covers subclass features, its pretty much the same
class ClassFeature
	attr_accessor :name, :level, :description, :other_features_referenced, :subclass
    def initialize(raw_json, subclass)
        @name = raw_json["name"]
        @level = raw_json["level"].to_i
		@other_features_referenced = []
		@subclass = subclass
		@description = flatten_entries(raw_json["entries"])
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

	def to_s
		"#{name} - lvl #{level}#{ subclass.nil? ? "" : " - #{subclass} subclass feature" }\n#{description}"
	end
end
