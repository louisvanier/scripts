class SpellSource
    def initialize(data, sourcename)
        @data = data
        @sourcename = sourcename
    end

    def load_spells(spell_selection, caster_levels)
        @data["spell"].map do |s|
            yield Spell.new(parse_spell(s).merge(caster_level: caster_levels.fetch(:sorcerer, 1))) if !spell_selection || spell_selection.include?(normalize_spell_name(s["name"])) 
        end
    end

    private

    def normalize_spell_name(str)
        str.strip.downcase.gsub(/\s+/, ' ')
    end

    def parse_spell(data)
    {
      name: data["name"],
      level: data["level"],
      casting_time: data["time"]&.map { |t| "#{t['number']} #{t['unit']}" }&.join(', '),
      range: data["range"],
      components: data["components"].map { |k, v| ['v', 's'].include?(k) ? k.upcase : "#{k.upcase} => #{v}"},
      duration: data["duration"],
      source: "#{data['source']}#{' p.' + data['page'].to_s if data['page']}",
      description: flatten_entries(data["entries"]),
      school: data["school"],
      entries_higher_level: data["entriesHigherLevel"],
      ritual: data["meta"] && data["meta"]["ritual"]
    }
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
        else
            ""
        end
      else ""
      end
    end.join("\n\n")
  end
end
