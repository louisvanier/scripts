class CharacterClass
    CLASSES = ['artificer', 'bard', 'barbarian', 'cleric', 'druid', 'fighter', 'monk', 'paladin', 'ranger', 'rogue', 'sorcerer', 'wizard'].freeze

    attr_accessor :primary_attribute, :hit_die_size, :saves_proficiency, :spellcasting_ability, :caster_progression

    def initialize(data_provider, character_class)
        @data_provider = data_provider
        @character_class = character_class

        class_details = data_provider["class"]
        primary_attribute = class_details["primaryAbility"][0].key
        hit_die_size = class_details["hd"]["faces"]
        saves_proficiency = class_details["proficiency"]
        spellcasting_ability = class_details["spellcastingAbility"]
        caster_progression = class_details["casterProgression"]
    end
end
