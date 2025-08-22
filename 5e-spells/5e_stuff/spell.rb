class Spell
  attr_accessor :name, :level, :casting_time, :range, :components,
                :duration, :source, :description, :url, :school,
                :entries_higher_level, :caster_level, :ritual,
                :damage_types, :saving_throws, :damage_inflict

  def initialize(attrs = {})
    attrs.each { |k, v| send("#{k}=", v) }
  end

  def school_name
    case school
    when 'T' then 'Transmutation'
    when 'A' then 'Abjuration'
    when 'V' then 'Evocation'
    when 'E' then 'Enchantment'
    when 'N' then 'Necromancy'
    when 'I' then 'Illusion'
    when 'C' then 'Conjuration'
    when 'D' then 'Divination'
    else "#{school} UNKNOWN SCHOOL"
    end
  end

  def level_to_s
    return level if level > 0

    str = 'Cantrip'
    str += ", upgraded @ caster level #{caster_level}" if cantrip_upgraded?
    str
  end

  def scales_at_higher_level?
    entries_higher_level&.any? { |e| e['name'] == 'Using a Higher-Level Spell Slot' }
  end

  def adjusted_description
    return description unless cantrip_upgraded?

    breakpoint = if caster_level >= 17
                   17
                 else
                   caster_level >= 11 ? 11 : 5
                 end
    actual_damage = entries_higher_level.map do |e|
      e['entries'].join("\n")
    end.join.match(/#{breakpoint} (?<actual_damage>\(\{@damage \d+d\d+\}\))/i).captures.join('')
    description.gsub(/\{@damage \d+d\d+\}/, actual_damage)
  end

  def cantrip_upgraded?
    return false unless level == 0
    return false unless caster_level >= 5
    return false unless entries_higher_level

    entries_higher_level&.any? { |e| e['name'] == 'Cantrip Upgrade' }
  end

  def duration_to_s
    return duration[0]['type'] if %w[instant special permanent].include?(duration[0]['type'])

    dur = "#{duration[0]['duration']['amount']} #{duration[0]['duration']['type']}"
    dur += ' (Concentration)' if requires_concentration?
    dur
  end

  def requires_concentration?
    duration[0]['concentration']
  end

  def range_to_s
    return 'self' if range['distance']['type'] == 'self'

    distance_str = "#{range['distance']['type'] == 'touch' ? '' : "#{range['distance']['amount']} "}#{range['distance']['type']}"
    return distance_str if range['type'] == 'point'

    "#{distance_str} #{range['type']}"
  end

  def components_to_s(_include_non_consumable = false)
    components.map { |c| c.start_with?('M => ') && !c.end_with?('a reagent') ? 'M => $$$' : c }.compact.join(',')
  end

  def to_s
    lines = [
      "#{name} (#{school_name} #{level_to_s})#{scales_at_higher_level? ? ' *' : ''}",
      "Cast: #{casting_time}, #{components.join(', ')}",
      "#{range_to_s}, #{duration_to_s}",
      adjusted_description
    ]

    lines << "* #{entries_higher_level.map { |e| e['entries'].join("\n") }.join("\n")}" if scales_at_higher_level?

    lines.join("\n")
  end

  def to_summary
    "#{name} (#{school_name} #{level_to_s})#{scales_at_higher_level? ? ' *' : ''}#{requires_concentration? ? ' (C)' : ''}"
  end

  def to_compact_list
    damage_types = damage_types&.map do |dmg|
      Spellbook::DAMAGE_TYPES_EMOJI_MAP[dmg] || dmg
    end&.join(' / ')
    "#{damage_types}#{name} (#{school_name} | #{level_to_s})#{scales_at_higher_level? ? ' *' : ''}#{requires_concentration? ? ' (C)' : ''}"
  end

  def to_compact_list_line_two
    "#{components_to_s} | #{range_to_s} | #{duration_to_s}"
  end

  def to_short_summary
    "#{name} (lvl #{level_to_s})#{scales_at_higher_level? ? ' *' : ''}#{requires_concentration? ? ' (C)' : ''}"
  end

  def to_h
    {
      name: name,
      level: level,
      casting_time: casting_time,
      range: range,
      components: components,
      duration: duration,
      source: source,
      description: description,
      url: url,
      school: school
    }
  end

  def <=>(other)
    return name <=> other.name if other.level == level

    level <=> other.level
  end
end
