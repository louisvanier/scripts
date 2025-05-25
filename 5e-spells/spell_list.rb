require './character_class.rb'

class SpellList
    class << self
        CharacterClass::CLASSES.each do |cls|
            define_method("list_for_#{cls}".to_sym) do |**arg|
                pp "list_for_#{cls} #{arg}"
                return SpellList.new(arg[:provider], cls, nil, arg[:sources])
            end
        end
    end

    def initialize(data_provider, cls, subclass, sources)
        @data_provider = data_provider
        @class = cls
        @subclass = subclass
        @sources = sources
    end

    def get_spell_list
        sources.map do |source|
            data_provider.get_spell_lists[source].filter do |_, details|
                spell_matches_class(details) || spell_matches_subclass(details)
            end.map { |spell, _| spell }
        end.flatten
    end

    private

    def spell_matches_class(raw_spell_data)
        !details["class"].nil? && details["class"].any? { |s, classes| classes.keys.include?(character_class) } 
    end

    def spell_matches_subclass(raw_spell_data)
        !subclass.nil? && !details["subclass"].nil? && details["subclass"].any? { |s, subclasses| sources.include?(s); pp details["subclass"][s]}
    end
end
