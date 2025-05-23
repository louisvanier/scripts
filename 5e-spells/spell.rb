class Spell
  attr_accessor :name, :level, :casting_time, :range, :components,
                :duration, :source, :description, :url, :school,
                :entries_higher_level, :caster_level, :ritual

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
    return self.level if level > 0
    str = "Cantrip"
    if cantrip_upgraded? then
        str += ", upgraded @ caster level #{caster_level}"
    end
    return str
  end

  def scales_at_higher_level?
    self.entries_higher_level&.any? { |e| e["name"] == "Using a Higher-Level Spell Slot"}
  end

  def adjusted_description
    return self.description unless cantrip_upgraded?
    breakpoint = caster_level >= 17 ? 17 : caster_level >= 11 ? 11 : 5
    actual_damage = self.entries_higher_level.map { |e| e["entries"].join("\n")}.join().match(/#{breakpoint} (?<actual_damage>\(\{@damage \d+d\d+\}\))/i).captures.join("")
    self.description.gsub(/\{@damage \d+d\d+\}/, actual_damage)
  end

  def cantrip_upgraded?
    return false unless level == 0
    return false unless caster_level >= 5
    return false unless self.entries_higher_level
    return self.entries_higher_level&.any? { |e| e["name"] == "Cantrip Upgrade"}
  end

  def duration_to_s
    return duration[0]["type"] if %w(instant special).include?(duration[0]["type"])
    dur = "#{duration[0]["duration"]["amount"]} #{duration[0]["duration"]["type"]}"    
    dur += " (Concentration)" if requires_concentration?
    return dur
  end

  def requires_concentration?
    return duration[0]["concentration"]
  end

  def range_to_s
    return "self" if range["distance"]["type"] == "self"
    distance_str = "#{range["distance"]["type"] == "touch" ? "" : "#{range["distance"]["amount"]} "}#{range["distance"]["type"]}"
    return distance_str if range["type"] == "point"
    return "#{distance_str} #{range["type"]}"
  end

  def to_s
    lines = [
        "#{self.name} (#{self.school_name} #{self.level_to_s})#{self.scales_at_higher_level? ? " *" : "" }",
        "Cast: #{self.casting_time}, #{self.components.join(', ')}",
        "#{self.range_to_s}, #{self.duration_to_s}",
        self.adjusted_description,
    ]

    if scales_at_higher_level?
        lines << "* #{self.entries_higher_level.map { |e| e["entries"].join("\n") }.join("\n")}"
    end
    
    lines.join("\n")
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
end
