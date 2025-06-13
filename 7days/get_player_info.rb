require 'pathname'
require 'optparse'
require 'logger'

params = {
}

OptionParser.new do |opts|
  opts.on('-p PATH', '--player-files-path PATH', 'path to player files *.ttp') do |p|
    params[:'player-save-files-path'] = p
  end
end.parse!(into: params)

NON_CRAFTING_MAGAZINES = %w(firemansalmanac nightstalker luckylooter enforcer batterup greatheist wastetreasures huntingjournal artofmining rangers pistolpete shotgunmessiah sniper autoweapons urbancombat
          techjunkie barbrawling spearhunter)
ATTRIBUTES = %w(perception strength fortitude agility intellect)

class SevenDaysPlayer
  attr_reader :player_name, :crafting_skills, :perks, :odd_shits

  def initialize(save_file_path)
    @save_file_path = save_file_path
    @reader = BinaryFileReader.new(@save_file_path)
    @crafting_skills = {}
    @non_crafting_mags = {}
    @perks = []
    @odd_shits = {}
    @attributes = {}
    @hashes = []
    @shits_before_name = []
  end

  def parse_save_file
    while !@reader.eof?
      while @player_name.nil?
        str = @reader.get_str
        if str =~ /(vanier|Elvis|sauvage|2000)/
          @player_name = str
          @name_ofs = @reader.ofs
        end
      end
      c = @reader.get(1)
      if c.ord == 123 # {
        @hashes << @reader.get_hash
      elsif !str.nil?
        str = c + @reader.get_str
        if str =~ /crafting/
          # HMMM, is our last character outside of a-z?
          if str[-1].ord < 97 || str[-1].ord > 122
            skill_level = @reader.get(1, @reader.ofs - 2).ord
            @crafting_skills[str[0..-2].gsub(/crafting/, '')] = skill_level if skill_level > 1
          else
            skill_level = @reader.get(1, @reader.ofs - 1).ord
            @crafting_skills[str.gsub(/crafting/, '')] = skill_level if skill_level > 1
          end
        elsif str =~ /perk/
          got_perk = @reader.get(1, @reader.ofs - 1).ord
          if !(non_crafting_mag = NON_CRAFTING_MAGAZINES.find { |mag| str =~ /#{mag}/ }).nil?
            if got_perk == 1
              @non_crafting_mags[non_crafting_mag] ||= []
              @non_crafting_mags[non_crafting_mag] << str.gsub('perk', '').gsub(/(#{non_crafting_mag})(.*)/, '\2')
            end
          elsif got_perk == 1
            @perks << str.gsub('perk', '')
          end
        elsif str =~ /att\w+/
          attribute_level = @reader.get(1, @reader.ofs - 1).ord
          @attributes[str.gsub('att', '')] ||= {}
          @attributes[str.gsub('att', '')]['rating'] = attribute_level
        elsif str =~ /skill/ && !(attri  = ATTRIBUTES.find { |att| str =~ /#{att}/ }).nil?
          @attributes[attri] ||= {}
          @attributes[attri][str.gsub('skill', '').gsub(/#{attri}/, "")] = @reader.get(1, @reader.ofs - 1).ord
        elsif str !~ /(craft|place|gather|harvest|skill|buff)/

          maybe = @reader.get(1, @reader.ofs - 1).ord unless @reader.eof?
          @odd_shits[str] = maybe unless maybe.nil? || maybe == 0
        end
      end
    end
  end

  def show_stuff
    puts "\n"
    puts "#{@player_name} ---> found at offset #{@name_ofs}"
    puts "*** PERK MAGZS"
    pp @non_crafting_mags
    puts "*** OTHER PERKS"
    pp @perks
    puts "*** CRAFTING"
    pp @crafting_skills
    puts "*** BASE ATTRIBUTES"
    pp @attributes
    #puts "*** ALL ELSE?"
    #pp @odd_shits.keys
    puts "\n"
  end
end

class BinaryFileReader
  attr_reader :ofs
  def initialize(path)
    @path = Pathname(path)
    @data = @path.open("rb", &:read)
    @ofs = 0
  end

  def get(n, offset = @ofs)
    fail! "Trying to read past end of file" if bytes_left < n
    result = @data[offset, n]
    @ofs = offset + n
    result
  end

  # assumes that you've already found { and are looking for }. Does not recurse yet for deeply nested hashes
  def get_hash
    result = ""
    c = "\x00"
    result << c while !eof? && (c = get(1)) && c.ord != 125
    result
  end

  def get_str
    result = ""
    c = "\x00"
    result << c while !eof? && (c = get(1)) && c.ord >= 32 && c.ord <= 126
    result
  end

  def bytes_left
    @data.size - @ofs
  end

  def eof?
    @data.size == @ofs
  end

  def fail!(message)
    raise "#{message} at #{@path}:#{@ofs}"
  end

  def get_u1
    get(1).unpack("C")[0]
  end

  def get_u2
    get(2).unpack("S")[0]
  end

  def get_u4
    get(4).unpack("L")[0]
  end

  def get_i4
    get(4).unpack("l")[0]
  end
end

@logger ||= Logger.new(STDOUT)
players = []
Dir.glob(File.join(params[:'player-save-files-path'], '*.ttp')).each do |player|
  @logger.debug("reading #{player}")
  player = SevenDaysPlayer.new(player)
  player.parse_save_file
  player.show_stuff
  players << player
end

pp players.map {|p| p.odd_shits.keys }.inject(:&)
