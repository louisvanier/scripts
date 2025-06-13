require './character_class.rb'

class SpellList
    class << self
        CharacterClass::CLASSES.each do |cls|
            define_method("list_for_#{cls}".to_sym) do |**arg|
                return SpellList.new(arg[:provider], cls, arg[:subclass], arg[:sources])
            end
        end
    end

    def initialize(data_provider, cls, subclass, sources)
        @data_provider = data_provider
        @klass = cls.downcase
        @subclass = subclass
        @sources = sources.map(&:upcase)
    end

    def subclass_additional_spells
        # possibly check for 
        # @sources.map do |source|
        #     source_spells = @data_provider.get_spell_lists[source.downcase]&.filter do |_, details|
        #         spell_matches_subclass(details["subclass"])
        #     end&.map { |spell, _| spell }
        #     source_spells&.compact
        # end.flatten.compact
    end

    def get_spell_list
        @sources.map do |source|
            source_spells = @data_provider.get_spell_lists[source.downcase]&.filter do |_, details|
                spell_matches_class(details["class"]) || spell_matches_subclass(details["subclass"])
            end&.map { |spell, _| spell }
            source_spells&.compact
        end.flatten.compact
    end

    private

    def spell_matches_class(class_data)
        return false if class_data.nil?
        @sources.each do |source|
            next unless class_data.key?(source)
            return class_data[source].keys.map(&:downcase).include?(@klass)
        end
        return false
    end

    def spell_matches_subclass(data)
        return false if data.nil?
        @sources.each do |source|
            next unless data.keys.include?(source)

            case data[source]
                in Hash => classes
                classes.each do |class_name, subsource_hash|
                    subsource_hash.each do |subsource, subclasses|
                        case subclasses
                        in Hash => sub_map
                            return true if sub_map.key?(@subclass)
                        end
                    end
                end
            end
        end
        false 
    end
end
