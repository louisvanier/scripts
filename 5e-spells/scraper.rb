require 'httparty'
require 'json'
require 'fileutils'
require 'logger'

require './spell.rb'
require './spellbook.rb'
require './spell_source.rb'
require './character_sheet.rb'
require './class_levels.rb'

class Scraper
  BASE_URL = "https://5e.tools/data/spells"
  LOCAL_DIR = "data"
  SPELLS_DATA_PREFIX = "spells-"
  CLASSES_PREFIX = "class-"
  KNOWN_NO_SPELLS_SOURCES = ['dsotdq']

  class << self
    # TODO MOVE TO USING AN ACTUAL LOGGER
    def log_level
      Logger::WARN
    end

    def logger
      if !defined?(@logger)
        @logger = Logger.new(STDOUT)
        @logger.level = log_level
      end
      @logger
    end
  end

  def initialize()
    @spell_sources = {}
    @character_classes = {}
    FileUtils.mkdir_p(LOCAL_DIR)
  end

  def get_spell_lists
    if !defined?(@spell_lists)
        @spell_lists = load_or_download(File.join(LOCAL_DIR, "#{SPELLS_DATA_PREFIX}lists.json"), "")
    end

    @spell_lists
  end

  def get_spell_source(source)
    if !@spell_sources.key?(source) && !KNOWN_NO_SPELLS_SOURCES.include?(source)
        @spell_sources[source] = SpellSource.new(load_or_download(File.join(LOCAL_DIR, "#{SPELLS_DATA_PREFIX}#{source}.json"), source), source)
    end
    @spell_sources[source]
  end

  def get_character_class(cls)
    if !@character_classes.key?(cls)
        @character_classes[cls] = load_or_download(File.join(LOCAL_DIR, "#{CLASSES_PREFIX}#{cls}.json"), cls)
    end
    @character_classes[cls]
  end

  private

  def load_or_download(file_path, source_code)
    if File.exist?(file_path)
      Scraper.logger.info "🔍 Loading local file: #{file_path}"
      JSON.parse(File.read(file_path))
    else
      url = "#{BASE_URL}/spells-#{source_code}.json"
      Scraper.logger.info "🌐 Downloading from #{url}"
      response = HTTParty.get(url, headers: fake_headers)
      if response.code == 200
        File.write(file_path, response.body)
        JSON.parse(response.body)
      else
        Scraper.logger.error "❌ Failed to fetch #{url}: #{response.code}"
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
sources = ['xphb', 'xge', 'tce', 'dsotdq']
spells_sans_croc = ['Creation','Absorb Elements','Alter Self','Blindness/Deafness','Chill Touch','Color Spray','Dispel Magic','Enhance Ability','Hypnotic Pattern','Invisibility','Lesser Restoration', 'Mage Hand', 'Mending', 'Message', 'Phantom Steed', 'Prestidigitation', 'Ray of Sickness', 'Sacred Flame', 'Shape Water', 'Shield', 'Silent Image', 'Tasha’s Caustic Brew', 'Vampiric Touch', 'Vortex Warp', 'Dimension Door']

# book.spells.each do |spell|
#   puts spell.to_summary
#   puts "-" * 40
# end


players = []
players << CharacterSheet.new(char_name: 'Sans-croc', player_name: 'Louis V.', klass_levels: [ClassLevels.new(character_class: 'sorcerer', level: 7, choices: { subclass: 'lunar sorcery'}, source: "XPHB")], source: "XPHB",  str: 8, dex: 17, con: 14, int: 10, wis: 10, cha: 18, provider: provider, learned_spells: spells_sans_croc)
players << CharacterSheet.new(char_name: 'Florianz', player_name: 'Francis M.', klass_levels: [ClassLevels.new(character_class: 'cleric', level: 7, choices: { subclass: 'trickery domain'}, source: "XPHB")], source: "XPHB", str: 8, dex: 17, con: 14, int: 10, wis: 10, cha: 18, provider: provider, learned_spells: [])
players << CharacterSheet.new(char_name: 'Alfonso', player_name: 'Olivier P.', klass_levels: [ClassLevels.new(character_class: 'artificer', level: 7, choices: { subclass: 'battle smith'}, source: "TCE")], source: "XPHB", str: 8, dex: 17, con: 14, int: 10, wis: 10, cha: 18, provider: provider, learned_spells: [])
players << CharacterSheet.new(char_name: 'Guillemain', player_name: 'Maxime T.', klass_levels: [ClassLevels.new(character_class: 'rogue', level: 7, choices: { subclass: 'assassin'}, source: "XPHB")], source: "XPHB", str: 8, dex: 17, con: 14, int: 10, wis: 10, cha: 18, provider: provider, learned_spells: [])
players << CharacterSheet.new(char_name: 'Clovis', player_name: 'David R.', klass_levels: [ClassLevels.new(character_class: 'ranger', level: 7, choices: { subclass: 'gloom stalker'}, source: "XPHB")], source: "XPHB", str: 8, dex: 17, con: 14, int: 10, wis: 10, cha: 18, provider: provider, learned_spells: [])
players << CharacterSheet.new(char_name: 'Tobiash', player_name: 'Alex G.', klass_levels: [ClassLevels.new(character_class: 'barbarian', level: 7, choices: { subclass: 'path of the world tree'}, source: "XPHB")], source: "XPHB", str: 8, dex: 17, con: 14, int: 10, wis: 10, cha: 18, provider: provider, learned_spells: [])
players << CharacterSheet.new(char_name: 'Taureau Ecarlate', player_name: 'David B.', klass_levels: [ClassLevels.new(character_class: 'monk', level: 7, choices: { subclass: 'way of shadow'}, source: "XPHB")], source: "XPHB", str: 8, dex: 17, con: 14, int: 10, wis: 10, cha: 18, provider: provider, learned_spells: [])
players << CharacterSheet.new(char_name: 'Godefroy', player_name: 'Julien G.', klass_levels: [ClassLevels.new(character_class: 'paladin', level: 7, choices: { subclass: 'oath of glory'}, source: "XPHB")], source: "XPHB", str: 8, dex: 17, con: 14, int: 10, wis: 10, cha: 18, provider: provider, learned_spells: [])
players.each do |player|
  puts "-" * 40
  player.print_summary
end

