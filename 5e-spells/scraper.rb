require 'httparty'
require 'json'
require 'fileutils'

require './spell.rb'

class Spellbook
  BASE_URL = "https://5e.tools/data/spells"
  LOCAL_DIR = "data"

  attr_reader :referenced_rules

  def initialize(caster_levels = { sorcerer: 1, wizard: 1, cleric: 1, paladin: 1, ranger: 1, bard: 1 }, whitelist = nil, sources: ["xphb"])
    @whitelist = whitelist&.map { |name| normalize(name) }
    @sources = sources.map(&:downcase)
    @caster_levels = caster_levels
    @referenced_rules = {}
    FileUtils.mkdir_p(LOCAL_DIR)
  end

  def fetch_spells
    all_spells = []

    @sources.each do |source_code|
      file_path = File.join(LOCAL_DIR, "spells-#{source_code}.json")
      data = load_or_download(file_path, source_code)
      next unless data && data["spell"]

      spells = data["spell"].select do |spell|
        !@whitelist || @whitelist.include?(normalize(spell["name"]))
      end

      all_spells.concat(spells.map { |s| Spell.new(parse_spell(s)) })
    end

    all_spells
  end

  private

  def load_or_download(file_path, source_code)
    if File.exist?(file_path)
      puts "🔍 Loading local file: #{file_path}"
      JSON.parse(File.read(file_path))
    else
      url = "#{BASE_URL}/spells-#{source_code}.json"
      puts "🌐 Downloading from #{url}"
      response = HTTParty.get(url, headers: fake_headers)
      if response.code == 200
        File.write(file_path, response.body)
        JSON.parse(response.body)
      else
        puts "❌ Failed to fetch #{url}: #{response.code}"
        nil
      end
    end
  end

  def normalize(str)
    str.strip.downcase.gsub(/\s+/, ' ')
  end

  def parse_spell(data)
    description = flatten_entries(data["entries"])

    rules_found = description&.match(/{(@[^{]+)}/)&.captures
    rules_found&.filter { |r| r.include?("|") }&.each do |r|
        pp r
        referenced_rules[r.split("|")[0]] ||= []
        referenced_rules[r.split("|")[0]] << data["name"]
    end
    {
      name: data["name"],
      level: data["level"],
      casting_time: data["time"]&.map { |t| "#{t['number']} #{t['unit']}" }&.join(', '),
      range: data["range"],
      components: data["components"].map { |k, v| ['v', 's'].include?(k) ? k.upcase : "#{k.upcase} => #{v}"},
      duration: data["duration"],
      source: "#{data['source']}#{' p.' + data['page'].to_s if data['page']}",
      description: description,
      school: data["school"],
      entries_higher_level: data["entriesHigherLevel"],
      caster_level: @caster_levels.fetch(:sorcerer, 1), # THIS SHOULD NOT BE HARDCODED
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

  def fake_headers
    {
      "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
      "Accept" => "application/json, text/plain, */*",
      "Accept-Language" => "en-US,en;q=0.9",
      "Referer" => "https://5e.tools/spells.html"
    }
  end
end


# --- Run the Scraper Example ---
pp 'running the scrape'
spells_sans_croc = ['Creation','Absorb Elements','Alter Self','Blindness/Deafness','Chill Touch','Color Spray','Dispel Magic','Enhance Ability','Hypnotic Pattern','Invisibility','Lesser Restoration', 'Mage Hand', 'Mending', 'Message', 'Phantom Steed', 'Prestidigitation', 'Ray of Sickness', 'Sacred Flame', 'Shape Water', 'Shield', 'Silent Image', 'Tasha’s Caustic Brew', 'Vampiric Touch', 'Vortex Warp', 'Dimension Door']
spellbook = Spellbook.new({sorcerer: 7}, spells_sans_croc, sources: ['xphb'])
spells = spellbook.fetch_spells.sort { |a, b| a.level <=> b.level }

spells.each do |spell|
  puts spell
  puts "-" * 40
end

pp spellbook.referenced_rules
