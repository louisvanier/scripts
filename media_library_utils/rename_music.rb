require 'pathname'
require 'fileutils'
require 'taglib'
require 'yaml'
require 'logger'
require 'optparse'

rename_songs = true
SAVE_TAGS = false
METADATA_FILE_NAME = 'metadata.yml'

params = {
  :write => false,
  :filter => '[Aa]*',
  :debug => 'WARN'
}
OptionParser.new do |opts|
  opts.on('-p PATH', '--library-path PATH', 'path of library') do |p|
    params[:'library-path'] = p
  end
  opts.on('-f FILTER', '--filter FILTER', 'unix style filter to scan only a subset of library') do |f|
    params[:filter] = f
  end
  opts.on('-d LOGGER_LEVEL', '--debug LOGGER_LEVEL', 'log level to output. Default is WARN')
  opts.on('-w', '--write', FalseClass, "Write changes to library path. Defaults is false for a dry-run") do |w|
    params[:write] = !w.nil?
  end
end.parse!(into: params)

def params

end

module Logging
  def logger
    Logging.logger
  end

  def self.logger
    # TODO correctly parse Log level from ARGV
    @logger ||= Logger.new(STDOUT)
  end
end

class BaseRule
  include Logging

  def initialize(renamer:)
    @renamer = renamer
  end

  def input
    @renamer.input
  end

  def log
    logger.debug("#{"\t"*log_indentation} #{self} -> #{@renamer.input}")
  end

  def log_indentation
    case @renamer
    when BandRenamer
      0
    when AlbumRenamer
      1
    when SongRenamer
      2
    end
  end
end

class RemoveBandNameRule < BaseRule
  def apply!
    log
    return if /^#{Regexp.escape(@renamer.band_name)}( [IVX]{1,2}| \d{1})?$/i =~ input
    # remove band name
    input.gsub!(/([^\w]|^)#{Regexp.escape(@renamer.band_name)}[^\w]/i, '')
  end
end

class RemoveAlbumNameRule < BaseRule
  def apply!
    log
    return if /^\d{2}\. #{Regexp.escape(@renamer.album_name)} ?([IVX]{1,2}|\d{1})?\.(mp3|aac|ogg|flac)/i =~ input
    input.gsub!(/([^\w]|^)#{Regexp.escape(@renamer.album_name)}([^\w]|^)/i, '')
  end
end

class UnderscoreToSpacesRule < BaseRule
  def apply!
    log
    input.gsub!('_', ' ')
  end
end

class RemoveYearRule < BaseRule
  def apply!
    return if input =~ /^\d{4}$/ # its already only a year, i.e. Rush - 2112, or the band 1349
    log
    year_found = input.scan(/([^\w]+|^)((19|20)\d{2})([^\w]+|$)/)&.flatten&.last&.to_i
    year_found = input.scan(/\(((19|20)\d{2})\)/)&.flatten&.last&.to_i if year_found.nil?
    year_found = input.scan(/\[((19|20)\d{2})\]/)&.flatten&.last&.to_i if year_found.nil?
    @renamer.album_year = year_found unless year_found.nil?
    input.gsub!(/\s+((19|20)\d{2})\s+/)
    input.gsub!(/\(((19|20)\d{2})\)/)
    input.gsub!(/\[((19|20)\d{2})\]/)
  end
end

class NormalizeTrackNumberule < BaseRule
  def apply!
    log
    input.gsub!(/[^\d\w](\d{1,3})[^\d\.\w]/,'\1. ')
  end
end

class FetchNormalizedTrackNumberRule
  def apply!
    log
    @renamer.track_number = input.scan(/^(\d{2})\./)&.flatten&.last&.to_i
    input
  end
end

class BracketsToParenthesesRule < BaseRule
  def apply!
    log
    input.gsub!(/[\[\]]/, '[' => '(', ']' => ')')
  end
end

class RemoveEmptySeparatorsRule < BaseRule
  def apply!
    log
    input.gsub!(/([^\w] -|- [^\w]|\(\)|\[\])/, '')
  end
end

class DashSeparatorsToSpaceRule < BaseRule
  def apply!
    log
    input.gsub!(/ - /, ' ')
  end
end

class DuplicateSpaceRule < BaseRule
  def apply!
    log
    input.gsub!(/\s{2,}/, ' ')
  end
end

class LibraryRenamer
  include Logging

  def initialize(library_path:, band_filter:, write:, log_level:)
    abort("must supply the path of a directory containing your music library as first argument") unless File.directory?(library_path)
    @library_path = library_path
    @band_filter = band_filter
    @dry_run = !write
    Logging.logger.level = log_level
    log_params
  end

  def sanitize
  end

  def scan
    Dir.chdir(@library_path) do |library|
      Dir.glob(@band_filter).each do |band_folder|
        renamer = BandRenamer.new(band_folder_path: File.join(library, band_folder), dry_run: @dry_run)
        renamer.sanitize
      end
    end
  end

  private

  def log_params
    log_message = "library_path = #{@library_path}"
    log_message += ", filter = #{@band_filter}" if @band_filter
    log_message += ", dry-run!" if @dry_run
    Logging.logger.info log_message
  end
end

class BandRenamer
  include Logging

  attr_accessor :input

  def default_rules
    [UnderscoreToSpacesRule]
  end

  def initialize(band_folder_path:, dry_run:, rules: default_rules)
    @rules = rules
    @band_folder_path = Pathname.new(band_folder_path)
    @input = @band_folder_path.basename.to_s
    @dry_run = dry_run
  end

  def sanitize
    @band_name = input
    actual_rules.each(&:apply!)

    logger.info "#{@band_name}"
    if @band_name != @band_folder_path.basename.to_s
      logger.info "#{@band_name} !!! WAS SANITIZED FROM #{@band_folder_path.basename.to_s}"
      unless @dry_run
        FileUtils.mv(band_folder_path, "#{band_folder_path.dirname}/#{@band_folder}")
      end
    end

    scan_band_folder

    @band_name
  end

  private

  def actual_rules
    @actual_rules ||= @rules.map { |r| r.new(renamer: self) }
  end

  def scan_band_folder
    Dir.each_child(@band_folder_path) do |album|
      album_folder_path = File.join(@band_folder_path, album)
      next unless File.directory?(album_folder_path)
      renamer = ::AlbumRenamer.new(album_folder_path: album_folder_path, band_name: @band_name, dry_run: @dry_run)
      sanitized = renamer.sanitize
    end
  end
end

class AlbumRenamer
  include Logging

  attr_accessor :album_year, :band_name, :input
  attr_reader :album_name

  def default_rules
    [
      UnderscoreToSpacesRule,
      RemoveYearRule,
      RemoveEmptySeparatorsRule,
      RemoveBandNameRule,
      RemoveEmptySeparatorsRule,
      BracketsToParenthesesRule,
      RemoveEmptySeparatorsRule,
      DashSeparatorsToSpaceRule,
      RemoveEmptySeparatorsRule,
      DuplicateSpaceRule
    ]
  end

  def initialize(album_folder_path:, band_name:, dry_run:, rules: default_rules)
    @rules = rules
    @album_folder_path = Pathname.new(album_folder_path)
    @input = @album_folder_path.basename.to_s
    @band_name = band_name
    @dry_run = dry_run
  end

  def sanitize
    actual_rules.each(&:apply!)

    logger.info("   FOUND YEAR IN ALBUM NAME => #{album_year}") if @album_year
    logger.info("   WRITING METADATA IN #{@album_folder_path}")
    if input != @album_folder_path.basename.to_s
      logger.info "   #{@album_folder_path.basename} ---> #{input}"
      unless @dry_run
        FileUtils.mv(@album_folder_path, "#{@album_folder_path.dirname}/#{input}")
        write_metadata(input)
      end
    else
      logger.info "   #{@album_folder_path.basename}"
    end
    sanitize_songs(input)

   input
  end

  def write_metadata(album_name)
    logger.info("WRITING METADATA IN #{@album_folder_path}")
    known_metadata = {band: @band_name, album: album_name}
    known_metadata[:year] = album_year unless album_year.nil?
    File.write("#{@album_folder_path}/metadata.yml", known_metadata.to_yaml)
  end

  private

  def actual_rules
    @actual_rules ||= @rules.map { |r| r.new(renamer: self) }
  end

  def sanitize_songs(sanitized_album)
    Dir.each_child(@album_folder_path) do |song|
      next unless /(mp3|aac|ogg|flac)$/ =~ song
      renamer = ::SongRenamer.new(song_path: File.join(@album_folder_path, song), album_name: sanitized_album, band_name: @band_name, dry_run: @dry_run)
      sanitized = renamer.sanitize
    end
  end
end

class SongRenamer
  include Logging

  attr_accessor :track_number, :album_name, :album_year, :input
  attr_reader :album_path, :band_name

  def default_rules
    [
      UnderscoreToSpacesRule,
      NormalizeTrackNumberule,
      RemoveBandNameRule,
      RemoveAlbumNameRule,
      RemoveYearRule,
      RemoveEmptySeparatorsRule,
      BracketsToParenthesesRule,
      RemoveEmptySeparatorsRule,
      DuplicateSpaceRule
    ]
  end

  def initialize(song_path:, album_name:, band_name:, dry_run:, rules: default_rules)
    @rules = rules
    @song_path = Pathname.new(song_path)
    @input = @song_path.basename.to_s
    @album_name = album_name
    @band_name = band_name
    @dry_run = dry_run
  end

  def sanitize
    actual_rules.each(&:apply!)

    logger.info("       TRACK NUMBER => #{track_number}") if @track_number
    if input != @song_path.basename.to_s
      logger.info "       #{@song_path.basename.to_s} ---> #{input}"
      unless @dry_run
        FileUtils.mv(@song_path, "#{@song_path.dirname}/#{input}")
      end
    end

    input
  end

  private

  def actual_rules
    @actual_rules ||= @rules.map { |r| r.new(renamer: self) }
  end
end

def update_common_tags!(tag:, artist: nil, album: nil, year: nil, track_number: nil)
  dirty = false
  if !artist.nil? && tag.artist != artist
    dirty = true
    tag.artist = artist
  end
  if !album.nil? && tag.album != album
    dirty = true
    tag.album = album
  end
  if !year.nil? && tag.year != year
    dirty = true
    tag.year = year.to_i
  end
  if !track_number.nil? && tag.track != track_number
    dirty = true
    tag.track = track_number
  end
  return dirty
end

def rename_songs(band_name:, album:, renamed_album:, year_found:)
  puts "#### ----- renaming songs -> #{band_name} : '#{renamed_album} ----- ####"
  Dir.glob(File.join(album,"*.{mp3,aac,ogg,flac}")).each do |song|

    begin
      # lets see if the tags are properly set. Will not try and save them if they are ok
      TagLib::FileRef.open(song) do |fileref|
        unless fileref.nil?
          if (update_common_tags!(tag: fileref.tag, artist: band_name, album: renamed_album, year: year_found, track_number: track_found))
            if SAVE_TAGS
              fileref.save
            end
            puts "updated tags -> #{song_renamed}"
          end
        end
      end
    rescue => e
      puts e
      puts "exception saving tags for #{band_name} : '#{renamed_album} -> #{song_renamed}"
    end

    # we've modified the song name, lets rename it
    if song_name != song_renamed
      # FileUtils.mv(song, "#{song_path.dirname}/#{song_renamed}")
      puts "#{song_path.basename} -> #{song_renamed}"
    end


  end
end

pp params
renamer = LibraryRenamer.new(library_path: params[:'library-path'], band_filter: params[:filter], write: params[:write], log_level: params[:debug])
renamer.scan
