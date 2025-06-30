class SevenDaysPlayer
  attr_accessor :name, :name_ofs, :crafting_skills, :perks, :odd_shits, :perk_magazines, :attributes

  ATTRIBUTES = { 
    'perception' => {
        'salvageoperations' => {
          'display_name' => 'Salvage Operations',
          'team_roles' => ['gatherer'],
        },
        'treasurehunter'=> {
          'display_name' => 'Treasure Hunter',
          'team_roles' => [],
        },
        'penetrator'=> {
          'display_name' => 'Penetrator',
          'team_roles' => [],
        },
        'animaltracker'=> {
          'display_name' => 'Animal Tracker',
          'team_roles' => ['food supply'],
        },
        'infiltrator'=> {
          'display_name' => 'Infiltrator',
          'team_roles' => [],
        },
        'flurryofperception'=> {
          'display_name' => 'Flurry of Perception',
          'team_roles' => [],
        },
        'javelinmaster'=> {
          'fighting' => 'melee',
          'weapon' => 'spears',
          'wants_perk' => 'spearhunter',
          'display_name' => 'Javelin Master',
          'team_roles' => [],
        },
        'demolitionsexpert'=> {
          'fighting' => 'other',
          'weapon' => 'explosives',
          'display_name' => 'Demolitions Expert',
          'team_roles' => [],
        },
        'deadeye'=> {
          'fighting' => 'ranged',
          'weapon' => 'rifles',
          'wants_perk' => 'sniper',
          'display_name' => 'Deadeye',
          'team_roles' => [],
        },
        'perceptionmastery' => {
          'display_name' => 'Perception Mastery',
          'team_roles' => [],
        },
    }, 
    'strength' => {
        'motherlode'=> {
          'display_name' => 'Motherlode',
          'team_roles' => ['gatherer'],
        },
        'miner69r'=> {
          'display_name' => 'Miner 69er',
          'team_roles' => ['gatherer'],
        },
        'junkminer'=> {
          'display_name' => 'Junk Miner',
          'team_roles' => ['gatherer'],
        },
        'packmule'=> {
          'display_name' => 'Pack Mule',
          'team_roles' => [],
        },
        'heavyarmor'=> {
          'display_name' => 'Heavy Armor',
          'team_roles' => [],
        },
        'flurryofstrength'=> {
          'display_name' => 'Flurry of Strength',
          'team_roles' => [],
        },
        'skullcrusher'=> {
          'fighting' => 'melee',
          'weapon' => 'sledges',
          'wants_perk' => 'sledgesaga',
          'display_name' => 'Skullcrusher',
          'team_roles' => [],
        },
        'grandslam'=> {
          'display_name' => 'Grand Slam',
          'team_roles' => [],
        },
        'pummelpete'=> {
          'fighting' => 'melee',
          'weapon' => 'clubs',
          'wants_perk' => 'batterup',
          'display_name' => 'Pummel Pete',
          'team_roles' => [],
        },
        'boomstick'=> {
          'fighting' => 'ranged',
          'weapon' => 'shotguns',
          'wants_perk' => 'shotgunmessiah',
          'display_name' => 'Boomstick',
          'team_roles' => [],
        },
        'strengthmastery' => {
          'display_name' => 'Strength Mastery',
          'team_roles' => [],
        },
    }, 
    'fortitude' => {
        'ruleonecardio'=> {
          'display_name' => 'Rule one: Cardio',
          'team_roles' => [],
        },
        'slowmetabolism'=> {
          'display_name' => 'Slow Metabolism',
          'team_roles' => [],
        },
        'healingfactor'=> {
          'display_name' => 'Healing Factor',
          'team_roles' => [],
        },
        'paintolerance'=> {
          'display_name' => 'Pain Tolerance',
          'team_roles' => [],
        },
        'thehuntsman'=> {
          'display_name' => 'The Huntsman',
          'team_roles' => ['food supply'],
        },
        'flurryoffortitude'=> {
          'display_name' => 'Flurry of Fortitude',
          'team_roles' => [],
        },
        'siphoningstrikes'=> {
          'display_name' => 'Siphoning Strikes',
          'team_roles' => [],
        },
        'machinegunner'=> {
          'fighting' => 'ranged',
          'weapon' => 'machine guns',
          'wants_perk' => 'autoweapons',
          'display_name' => 'Machine Gunner',
          'team_roles' => [],
        },
        'brawler'=> {
          'fighting' => 'melee',
          'weapon' => 'knuckles',
          'wants_perk' => 'barbrawling',
          'display_name' => 'Brawler',
          'team_roles' => [],
        },
        'fortitudemastery' => {
          'display_name' => 'Fortitude Mastery',
          'team_roles' => [],
        },
    }, 
    'agility' => {
        'fromtheshadows'=> {
          'display_name' => 'From The Shadows',
          'team_roles' => ['looter'],
        },
        'hiddenstrike'=> {
          'display_name' => 'Hidden Strike',
          'team_roles' => ['looter'],
        },
        'parkour'=> {
          'display_name' => 'Parkour',
          'team_roles' => [],
        },
        'runandgun'=> {
          'display_name' => 'Run And Gun',
          'team_roles' => [],
        },
        'hardtarget'=> {
          'display_name' => 'Hard Target',
          'team_roles' => [],
        },
        'flurryofagility'=> {
          'display_name' => 'Flurry of Agility',
          'team_roles' => [],
        },
        'deepcuts'=> {
          'fighting' => 'melee',
          'weapon' => 'knives',
          'display_name' => 'Deep Cuts',
          'team_roles' => [],
        },
        'gunslinger'=> {
          'fighting' => 'ranged',
          'weapon' => 'handguns',
          'wants_perk' => 'pistolpete',
          'display_name' => 'Gunslinger',
          'team_roles' => [],
        },
        'archery'=> {
          'fighting' => 'ranged',
          'weapon' => 'bows',
          'wants_perk' => 'rangers',
          'display_name' => 'Archery',
          'team_roles' => [],
        },
    },
    'intellect' => {
        'advancedengineering'=> {
          'display_name' => 'Advanced Engineering',
          'team_roles' => ['tech'],
        },
        'physician'=> {
          'display_name' => 'Physician',
          'team_roles' => ['healer'],
        },
        'charismaticnature'=> {
          'display_name' => 'Charismatic Nature',
          'team_roles' => [],
        },
        'daringadventurer'=> {
          'display_name' => 'Daring Adventurer',
          'team_roles' => [],
        },
        'betterbarter'=> {
          'display_name' => 'Better Barter',
          'team_roles' => [],
        },
        'flurryofintellect'=> {
          'display_name' => 'Flurry of Intellect',
          'team_roles' => [],
        },
        'turrets'=> {
          'fighting' => 'ranged',
          'weapon' => 'robotic turrets',
          'wants_perk' => 'techjunkie',
          'display_name' => 'Robotics',
          'team_roles' => [],
        },
        'electrocutioner'=> {
          'fighting' => 'melee',
          'weapon' => 'stun baton',
          'wants_perk' => 'techjunkie',
          'display_name' => 'Electocutioner',
          'team_roles' => [],
        },
    },
    'general' => {
      'lightarmor' => {
        'display_name' => 'Light Armor',
        'team_roles' => [],
      },
      'mediumarmor' => {
        'display_name' => 'Medium Armor',
        'team_roles' => [],
      },
      'heavyarmor' => {
        'display_name' => 'Heavy Armor',
        'team_roles' => [],
      },
      'masterchef' => {
        'display_name' => 'Master Chef',
        'team_roles' => ['food supply'],
      },
      'livingofftheland' => {
        'display_name' => 'Living Off The Land',
        'team_roles' => ['food supply'],
      },
      'lockpicking' => {
        'display_name' => 'Lockpicking',
        'team_roles' => ['looter'],
      },
      'luckylooter' => {
        'display_name' => 'Lucky Looter',
        'team_roles' => ['looter'],
      },
      'greasemonkey'=> {
        'display_name' => 'Grease Monkey',
        'team_roles' => ['tech'],
      },
    }
    
  }

  class << self
    def from_file(file_path)
      @logger ||= Logger.new(STDOUT)
      @logger.level = Logger::WARN
      reader = BinaryFileReader.new(file_path)
      return parse_save_file(reader)
    end

    def read_attribute(reader, str, player)
      match = SevenDaysPlayer::ATTRIBUTES.find do |attribute, details|
        str =~ /att#{attribute}/
      end

      return nil unless match
      reader.ofs = reader.ofs - 1
      rating = reader.get(1, reader.ofs).ord
      player.attributes[match[0]] ||= {}
      player.attributes[match[0]]['rating'] = rating
    end

    def read_attribute_perk(reader, str, player)
      att = nil
      perk = nil
      SevenDaysPlayer::ATTRIBUTES.each do |attribute, details|
        perk = details.find do |att_perk, perk_details|
          str =~ /perk#{att_perk}/
        end
        att = attribute unless perk.nil?
        break unless perk.nil?
      end

      return if perk.nil?
      reader.ofs = reader.ofs - 1
      rating = reader.get(1, reader.ofs).ord
      player.attributes[att] ||= {}
      player.attributes[att][perk[0]] = rating
    end

    def read_magazine_perk(reader, str, player)
      match = SevenDaysParty::PERK_MAGAZINES.find do |mag, details|
        str =~ /perk#{mag}/
      end

      return if match.nil?

      issue = SevenDaysParty::PERK_MAGAZINES[match[0]]['issues'].find { |iss| str =~ /perk#{match[0]}#{iss}/}

      return if issue.nil?
      reader.ofs = reader.ofs - 1
      rating = reader.get(1, reader.ofs).ord
      player.perk_magazines[match[0]] ||= []
      player.perk_magazines[match[0]] << issue if rating > 0
    end

    def read_crafting_skill(reader, str, player)
      match = SevenDaysParty::CRAFTING_SKILLS.find do |skill, details|
        str =~ /crafting#{skill}/
      end

      return nil unless match
      rating = if "crafting#{match[0]}" == str
        reader.ofs = reader.ofs - 1
        reader.get(1, reader.ofs).ord
      else
        str[-1].ord
      end

      return unless rating > 0
      
      player.crafting_skills[match[0]] ||= {}
      player.crafting_skills[match[0]] = rating
    end

    def parse_save_file(reader)
      player = SevenDaysPlayer.new
      while (str = reader.get_str) && !reader.eof?
        next if str.size < 4 || !(str =~ /sledge2ndHit/).nil?
        if player.name.nil? && str.size >= 6
          player.name  = str
          # first string that matters is the name We use 6 as the min length for the name only. Something better could probably be tried 
          # It should be the first actual string we pick up. Afterwards we'll try all the shit on every single string
        else
          read_attribute(reader, str, player)
          read_attribute_perk(reader, str, player)
          read_magazine_perk(reader, str, player)
          read_crafting_skill(reader, str, player)
        end
      end
      player
    end
  end


  def initialize()
    @crafting_skills = {}
    @perk_magazines = {}
    @perks = []
    @odd_shits = {}
    @attributes = {}
    @shits_before_name = []
  end

  def has_read_issue?(serie, issue)
    perk_magazines[serie]&.include?(issue)
  end

  def has_completed_perk_serie?(serie)
    perk_magazines[serie]&.size == 7
  end

  def perk_magazines_reference
    return SevenDaysParty::PERK_MAGAZINES
  end

  def link_friendly_name
    return name.gsub(' ', '')
  end

  def capped_crafting_skill?(skill)
    @crafting_skills[skill] == SevenDaysParty::CRAFTING_SKILLS[skill]['max_rank']
  end

  def top_attributes
    @top_attributes ||= @attributes.find_all{ |_, details| !details['rating'].nil? }.sort { |(_, details1), (_, details2)| details2['rating'] <=> details1['rating'] }.take(3)
  end

  def best_melee_skill_rating
    best_melee_skill
    @best_value
  end

  def best_melee_skill
    if !defined?(@best_value)
      @best_value = 0
      @best_spec_details = nil

      ATTRIBUTES.each do |att, details|
        details.find_all { |att_spec, spec_details| spec_details['fighting'] == "melee" }.each do |spec, det|
          if attributes[att][spec] > @best_value
            @best_spec_details = details[spec]
            @best_value = attributes[att][spec]
          end
        end
      end

      
    end
    @best_spec_details
  end

  def best_ranged_skill_rating
    best_ranged_skill
    @best_ranged_value
  end

  def best_ranged_skill
    if !defined?(@best_ranged_value)
      @best_ranged_value = 0
      @best__ranged_spec_details = nil

      ATTRIBUTES.each do |att, details|
        details.find_all { |att_spec, spec_details| spec_details['fighting'] == "ranged" }.each do |spec, det|
          if attributes[att][spec] > @best_ranged_value
            @best__ranged_spec_details = details[spec]
            @best_ranged_value = attributes[att][spec]
          end
        end
      end

      
    end
    @best__ranged_spec_details
  end
  
  def wants_perk?(serie)
    return -1 if (!best_melee_skill.nil? &&  best_melee_skill['wants_perk'] == serie) || (!best_ranged_skill.nil? && best_ranged_skill['wants_perk'] == serie )
    return 0
  end

  def party_roles
    roles = Hash.new { |k, v| k[v] = [] }
    # find_all attributes spec with a party role and rating above 0
    SevenDaysPlayer::ATTRIBUTES.map { |att_name, att_details| att_details  }
      .reduce(&:merge)
      .find_all { |spec_name, spec_details| attributes.any? { |att, specs| specs.any? { |spec, rating| spec == spec_name && rating > 0 } } && !spec_details['team_roles'].empty? }
      .each { |spec_name, spec_details| spec_details['team_roles'].each { |r| roles[r] << "#{spec_details['display_name']}"}}

      SevenDaysParty::CRAFTING_SKILLS.find_all { |skill, details| !details['team_roles'].nil? && @crafting_skills[skill] > (details['max_rank'] / 4) }
        .each { |skill, details| details['team_roles'].each { |r| roles[r] << "#{details['display_name']} @ #{@crafting_skills[skill]}"} }

    roles
  end

  def get_binding
    binding
  end
end
