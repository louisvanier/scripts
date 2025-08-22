class SpellList
  class << self
    CharacterKlass::CLASS_LIST.each do |cls, _|
      define_method("list_for_#{cls}".to_sym) do |**arg|
        SpellList.new(cls, arg[:subclass], arg[:sources])
      end
    end
  end

  def initialize(cls, subclass, sources)
    @klass = cls.downcase
    @subclass = subclass
    @sources = sources.map(&:upcase)
  end

  def subclass_additional_spells
    klass = CharacterKlass.send(@klass, source: 'XPHB')
    Scraper.logger.info "fetching extra spells for => #{@klass} - #{@subclass}"
    extra_spells = klass.subclass(@subclass)&.extra_spells
    Scraper.logger.info "XTRA SPELLS = #{extra_spells}"
    extra_spells
  end

  def get_known_spells(list)
    spell_list += @sources.map do |source|
      source_spells = Scraper.instance.get_spell_lists[source.downcase]&.filter do |_, _details|
        list.include?
      end&.map { |spell, _| spell }
      source_spells&.compact
    end.flatten.compact
    spell_list
  end

  def get_spell_list
    spell_list = subclass_additional_spells || []
    spell_list += @sources.map do |source|
      source_spells = Scraper.instance.get_spell_lists[source.downcase]&.filter do |_, details|
        spell_matches_class(details['class']) || spell_matches_subclass(details['subclass'])
      end&.map { |spell, _| spell }
      source_spells&.compact
    end.flatten.compact
    spell_list
  end

  private

  def spell_matches_class(class_data)
    return false if class_data.nil?

    @sources.each do |source|
      next unless class_data.key?(source)

      return class_data[source].keys.map(&:downcase).include?(@klass)
    end
    false
  end

  def spell_matches_subclass(data)
    return false if data.nil?

    @sources.each do |source|
      next unless data.keys.include?(source)

      case data[source]
      in Hash => classes
        classes.each do |_class_name, subsource_hash|
          subsource_hash.each do |_subsource, subclasses|
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
