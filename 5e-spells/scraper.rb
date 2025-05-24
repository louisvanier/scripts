require 'httparty'
require 'json'
require 'fileutils'

require './spell.rb'
require './spellbook.rb'
require './spell_source.rb'

class Scraper
  BASE_URL = "https://5e.tools/data/spells"
  LOCAL_DIR = "data"
  SPELLS_DATA_PREFIX = "spells-"

  attr_reader :referenced_rules

  def initialize()
    @spell_sources = {}
    FileUtils.mkdir_p(LOCAL_DIR)
  end

  def get_spell_source(source)
    if !@spell_sources.key?(source)
        pp source
        @spell_sources[source] = SpellSource.new(load_or_download(File.join(LOCAL_DIR, "#{SPELLS_DATA_PREFIX}#{source}.json"), source), source)
    end
    @spell_sources[source]
  end

  def load_spell
    Spell.new(parse_spell(s))
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

  def fake_headers
    {
      "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
      "Accept" => "application/json, text/plain, */*",
      "Accept-Language" => "en-US,en;q=0.9",
      "Referer" => "https://5e.tools/spells.html"
    }
  end
end

provider = Scraper.new
spells_sans_croc = ['Creation','Absorb Elements','Alter Self','Blindness/Deafness','Chill Touch','Color Spray','Dispel Magic','Enhance Ability','Hypnotic Pattern','Invisibility','Lesser Restoration', 'Mage Hand', 'Mending', 'Message', 'Phantom Steed', 'Prestidigitation', 'Ray of Sickness', 'Sacred Flame', 'Shape Water', 'Shield', 'Silent Image', 'Tasha’s Caustic Brew', 'Vampiric Touch', 'Vortex Warp', 'Dimension Door']
spellbook = Spellbook.new(provider, {sorcerer: 7}, spells_sans_croc, ['xphb'])
spells = spellbook.spells.sort { |a, b| a.level <=> b.level }

spells.each do |spell|
  puts spell
  puts "-" * 40
end

pp spellbook.referenced_rules
