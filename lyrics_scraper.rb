require 'httparty'
require 'nokogiri'

# required by locallibrary, not actual scraper
require 'pathname'
# required by YAMLLibrary, not the scraper
require 'yaml'

module LibraryCommon
    def total_songs
        data.reduce(0) do |total, (band, albums)|
            total += albums.reduce(0) { |sub, (album, songs)| sub += songs.size}
        end
    end

    def [](band)
        data[band.downcase]
    end

    def data
        @data ||= build_hash
    end

    def each(&block)
        data.each(&block)
    end
end

# implementation of a local music library to feed scraper
class LocalLibrary
    include LibraryCommon

    def initialize(base_path:)
        if !File.directory?(base_path)
            throw ArgumentException.new("path must be a readable directory pointing to the music Library")
        end
        @base_path = base_path
        @data = nil
    end

    def build_hash
        puts "reading media library"
        @data = {}
        Dir.glob("#{@base_path}/*").find_all { |band| File.directory?(band) }.each do |band|
            band_path = Pathname.new(band)
            band_name = band_path.basename.to_s.downcase
            if @data[band_name].nil?
                @data[band_name] = {}
            end
            Dir.glob("#{band}/*").each do |album|
                album_path = Pathname.new(album)
                album_name = album_path.basename.to_s.downcase
                if @data[band_name][album_name].nil?
                    @data[band_name][album_name] = []
                end
                Dir.glob("#{album}/*.{mp3,aac,ogg,flac}").each do |song|
                    song_path = Pathname.new(song)
                    song_name = searchable_song_name(song_path.basename.to_s)
                    @data[band_name][album_name] << song_name unless @data[band_name][album_name].include?(song_name)
                end
            end
        end
        puts "Done reading media library!"
        @data
    end

    def searchable_song_name(song_basename)
        return song_basename.gsub(/^\d{1,2}(\. | )/, '').gsub(/\.\w{3,}$/, '')
    end
end

class YAMLLibrary
    include LibraryCommon

    def initialize(yml_path:)
        if !File.exists?(yml_path)
            throw ArgumentException.new("path must be a readable yml file")
        end
        @yml_path = yml_path
        @data = nil
    end

    def build_hash
        puts "parsing YAML file"
        hash = YAML.load_file(@yml_path)
        puts "Done parsing YAML file!"
        hash
    end
end

# requires a library that responds to to_hash with something along the lines of { band1: { album1: [song1, song2, ...], ... }, ... }
# TODO => separate hard-dependency on genius.com for lyrics. Implement other lyric sources
class Scraper
    
    include HTTParty
    base_uri 'genius.com'

    MOCK_UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14.4; rv:125.0) Gecko/20100101 Firefox/125.0"
    MAX_SONGS_FOR_SCRAPE_ALL = 100
    REQUEST_WAIT = 20
    def initialize(library:, politeness: REQUEST_WAIT)
        @library = library
        @politeness = politeness
    end

    def scrape_all
        throw Exception.new('Too many songs to scrape, consider filtering') if limit_scraping && @library.total_songs > MAX_SONGS_FOR_SCRAPE_ALL
        estimated_total_wait = @library.total_songs * politeness
        puts "Wait time estimated is #{@estimated_total_wait / 60}m#{@estimated_total_wait % 60}s, not including the actual requests and scraping the content"
        @library.each do |band, _|
            scrape_artist_from_genius(artist: band)
        end
    end

    #band_filter is a regex
    def scrape_some_artits(band_filter:)
        matching_bands = @library.find_all { |band, _| /#{band_filter}/ =~ band}
    end

    def scrape_artist_from_genius(artist:)
        @library[artist.downcase].each do |album, songs|
            songs.each do |song|
                scrape_song_from_genius(artist: artist, song: song)
                sleep @politeness
            end
        end
    end

    def scrape_album_from_genius(artist:, album:)
        @library[artist.downcase][album.downcase].each do |song|
            scrape_song_from_genius(artist: artist, song: song)
            sleep @politeness
        end
    end

    def scrape_song_from_genius(artist:, song:)
        response = self.class.get("/#{artist.gsub(' ', '-')}-#{song.gsub(' ', '-')}-lyrics", { headers: { "User-Agent" => MOCK_UA}})
        puts "could not find lyrics on genius for #{artist} - #{song}" unless response.code >= 200 && response.code <= 300
        return unless response.code >= 200 && response.code <= 300
        lyrics = Nokogiri::HTML(response.body.gsub(/<br\/?>/, "\n")).css('div[data-lyrics-container]').map(&:text).join('')
        puts "#{song} ------"
        puts lyrics
        lyrics
    end

    private

    def limit_scraping
        ENV['SCRAPE_IT_ALL'] || 0
    end
end

scraper = Scraper.new(library: LocalLibrary.new(base_path: "/mnt/nas_music"))
