class Scraper
  BASE_URL = 'https://5e.tools/data/spells'
  LOCAL_DIR = 'data'
  SPELLS_DATA_PREFIX = 'spells-'
  CLASSES_PREFIX = 'class-'
  KNOWN_NO_SPELLS_SOURCES = ['dsotdq']

  class << self
    def instance
      @instance = Scraper.new unless defined?(@instance)

      @instance
    end

    def log_level
      Logger::WARN
    end

    def logger
      unless defined?(@logger)
        @logger = Logger.new(STDOUT)
        @logger.level = log_level
      end
      @logger
    end
  end

  def initialize
    @spell_sources = {}
    @character_classes = {}
    FileUtils.mkdir_p(LOCAL_DIR)
  end

  def get_spell_lists
    unless defined?(@spell_lists)
      @spell_lists = load_or_download(File.join(LOCAL_DIR, "#{SPELLS_DATA_PREFIX}lists.json"), '')
    end

    @spell_lists
  end

  def get_spell_source(source)
    if !@spell_sources.key?(source) && !KNOWN_NO_SPELLS_SOURCES.include?(source)
      @spell_sources[source] =
        SpellSource.new(load_or_download(File.join(LOCAL_DIR, "#{SPELLS_DATA_PREFIX}#{source}.json"), source), source)
    end
    @spell_sources[source]
  end

  def get_character_class(cls)
    unless @character_classes.key?(cls)
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
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      'Accept' => 'application/json, text/plain, */*',
      'Accept-Language' => 'en-US,en;q=0.9',
      'Referer' => 'https://5e.tools/spells.html'
    }
  end
end
