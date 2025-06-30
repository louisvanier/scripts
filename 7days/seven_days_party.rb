class SevenDaysParty
    attr_reader :players, :in_game_days, :in_game_hours

    PERK_MAGAZINES = {
        'artofmining' => {
            'display_name' => "Art of Mining",
            'image_name' => 'artofmining.png',
            'issues' => ['luckystrike', 'diamondtools', 'coffee', 'blackstrap', 'pallets', 'avalanche', 'damage'],
            'issues_display' => ['Vol. 1 : Lucky Strike', 'Vol. 2 : Diamond Tools', 'Vol. 3 : Coffee', 'Vol. 4 : Blackstrap', 'Vol. 5 : Resources', 'Vol. 6 : Avalanche', 'Vol. 7 : Damage']      
        },
        # TODO complete issues
        'autoweapons' => {
        'display_name' => "Automatic Weapon Handbook",
        'image_name' => 'autoweapons.webp',
        'issues' => ['damage', 'controlledburst', 'maintenance', 'drummag', 'recoil', 'ragdoll', 'machineguns'],
        'issues_display' => ['Vol. 1 : Damage', 'Vol. 2 : Uncontrolled Burst', 'Vol. 3 : Maintenance', 'Vol. 4 : Drum Magazines', 'Vol. 5 : Recoil', 'Vol. 6 : Ragdoll', 'Vol. 7 : Hip Fire']
        },
        # TODO complete issues
        'batterup' => {
        'display_name' => "Batter up!",
        'image_name' => 'batterup.webp',
        'issues' => ['bighits', 'stealingbases', 'slowpitch', 'knockdown', 'maintenance', 'foulballs', 'metalchain'],
        'issues_display' => ['Vol. 1 : Big Hits', 'Vol. 2 : Stealing Bases', 'Vol. 3 : Hit and Run', 'Vol. 4 : Knockdown', 'Vol. 5 : Maintenance', 'Vol. 6 : Foul Balls', 'Vol. 7 : Metal Chain Mod']
        },
        # TODO complete issues
        'barbrawling' => {
        'display_name' => "Bar Brawler",
        'image_name' => 'barbrawling.png',
        'issues' => ['1basicmoves', '2dropabomb', '3killerinstinct', '4finishingmoves', '5adrenalinehealing', '6ragemode', '7boozedup'],
        'issues_display' => ['Vol. 1 : basic Moves', 'Vol. 2 : Drop a Bomb', 'Vol. 3 : killer Instinct', 'Vol. 4 : Finishing Moves', 'Vol. 5 : Adrenaline Healing', 'Vol. 6 : Rage Mode', 'Vol. 7 : Boozed Up']
        },
        'firemansalmanac' => {
        'display_name' => "Fireman's Almanac",
        'image_name' => 'firemansalmanac.png',
        'issues' => ['heat', 'axes', 'speed', 'molotov', 'prevention', 'harvest', 'equipment'],
        'issues_display' => ['Vol. 1 : Conditioning', 'Vol. 2 : Mods', 'Vol. 3 : Speed', 'Vol. 4 : Fire with Fire', 'Vol. 5 : Prevention', 'Vol. 6 : Search and Rescue', 'Vol. 7 : Gear']
        },
        # TODO complete issues
        'greatheist' => {
        'display_name' => "Great Heist",
        'image_name' => 'greatheist.png',
        'issues' => ['safes', 'gems', 'goldrush', 'claimed', 'adrenalinefall', 'sprintsneak', 'motiondetection'],
        'issues_display' => ['Vol. 1 : Safes', 'Vol. 2 : Gems', 'Vol. 3 : Gold Rush', 'Vol. 4 : Claimed', 'Vol. 5 : Adrenaline Fall', 'Vol. 6 : Stealthy Sprinting', 'Vol. 7 : Motion Detection']
        },
        # TODO complete issues
        'huntingjournal' => {
        'display_name' => "Hunter's Journal",
        'image_name' => 'huntingjournal.png',
        'issues' => ['bears', 'wolves', 'coyotes', 'moutainlions', 'deers', 'vultures', 'selfdefense'],
        'issues_display' => ['Vol. 1 : Bears', 'Vol. 2 : Wolves', 'Vol. 3 : Coyotes', 'Vol. 4 : Moutain Lions', 'Vol. 5 : Deers', 'Vol. 6 : Vultures', 'Vol. 7 : Elf Defense']
        },
        # TODO complete issues
        'luckylooter' => {
        'display_name' => "Lucky Looter",
        'image_name' => 'luckylooter.webp',
        'issues' => ['dukes', 'ammunition', 'brass', 'lead', 'books', 'food', 'medical'],
        'issues_display' => ['Vol. 1 : Dukes', 'Vol. 2 : Ammunition', 'Vol. 3 : Brass', 'Vol. 4 : Lead', 'Vol. 5 : Junk', 'Vol. 6 : Food', 'Vol. 7 : Medical Supplies']
        },
        'enforcer' => {
        'display_name' => "Magnum Enforcer",
        'image_name' => 'enforcer.png',
        'issues' => ['damage', 'apparel', 'punks', 'intimidation', 'apammo', 'hpammo', 'criminalpursuit'],
        'issues_display' => ['Vol. 1 : Damage', 'Vol. 2 : Apparel', 'Vol. 3 : Unlucky Punks', 'Vol. 4 : Intimidation', 'Vol. 5 : Armor Piercing Ammunition', 'Vol. 6 : Hollow Point Ammunition', 'Vol. 7 : Criminal Pursuit']
        },
        # TODO complete issues, double check names
        'needle' => {
        'display_name' => "Needle & Thread",
        'image_name' => 'needle.png',
        'issues' => ['luckystrike', 'diamondtools', 'coffee', 'blackstrap', 'pallets', 'avalanche', 'damage'],
        'issues_display' => ['Vol. 1 : Winter Wear', 'Vol. 2 : Legwear', 'Vol. 3 : Footwear', 'Vol. 4 : Desert Wear', 'Vol. 5 : Dusters', 'Vol. 6 : Puffer Coats', 'Vol. 7 : Pockets']
        },
        # TODO complete issues, double check names
        'nightsalker' => {
        'display_name' => "Night Stalker",
        'image_name' => 'nightstalker.png',
        'issues' => ['stealthdamage', 'silentnight', 'blades', 'thiefadrenaline', 'archery', 'twilightthief', 'slumberparty'],
        'issues_display' => ['Vol. 1 : Stealth', 'Vol. 2 : Silent Night', 'Vol. 3 : Blades', 'Vol. 4 : Thief Adrenaline', 'Vol. 5 : Archery', 'Vol. 6 : Twilight Thief', 'Vol. 7 : Slumber Party']
        },
        'pistolpete' => {
        'display_name' => "Pistol Pete",
        'image_name' => 'pistolpete.png',
        'issues' => ['takeaim', 'swissknees', 'steadyhand', 'maintenance', 'hpammo', 'apammo', 'damage'],
        'issues_display' => ['Vol. 1 : Take Aim', 'Vol. 2 : Swiss Knees', 'Vol. 3 : Steady Hand', 'Vol. 4 : Maintenance', 'Vol. 5 : Hollow Point Ammunition', 'Vol. 6 : Piercing Ammunition', 'Vol. 7 : Maximum Damage']
        },
        # TODO complete issues, double check names
        'rangers' => {
        'display_name' => "Ranger's Guide to Archery",
        'image_name' => 'rangers.png',
        'issues' => ['arrowrecovery', 'explodingbolts', 'cripplingshot', 'apammo', 'flamingarrows', 'forestguide', 'knockdown'],
        'issues_display' => ['Vol. 1 : Arrow Recovery', 'Vol. 2 : Exploding Arrows', 'Vol. 3 : Crippling Shot', 'Vol. 4 : Armor Piercing Arrows', 'Vol. 5 : Flaming Arrows', 'Vol. 6 : Maintenance', 'Vol. 7 : Knockdown']
        },
        'shotgunmessiah' => {
        'display_name' => "Shotgun Messiah",
        'image_name' => 'shotgunmessiah.png',
        'issues' => ['damage', 'breachingslugs', 'limbshot', 'slugs', 'maintenance', 'magazine', 'partystarter'],
        'issues_display' => ['Vol. 1 : Damage', 'Vol. 2 : Breaching Ammunition', 'Vol. 3 : Limb Shot', 'Vol. 4 : Shotgun Slugs', 'Vol. 5 : Maintenance', 'Vol. 6 : Magazine Mods', 'Vol. 7 : Party Starter']
        },
        'sledgesaga' => {
        'display_name' => "Sledge Saga",
        'image_name' => 'sledgesaga.png',
        'issues' => ['knockdown', 'degradation', 'crippledmorale', 'pulverizingfinishers', 'savagereaper', 'concussivestrike', 'armorcrusher'],
        'issues_display' => ['Vol. 1 : Knockdown', 'Vol. 2 : Degradation', 'Vol. 3 : Crippled Morale', 'Vol. 4 : Pulverizing Finishers', 'Vol. 5 : Savage Reaper', 'Vol. 6 : Concussive Strike', 'Vol. 7 : Armor Crusher']
        },
        'sniper' => {
        'display_name' => "Sniper",
        'image_name' => 'sniper.png',
        'issues' => ['damage', 'cripplingshot', 'headshot', 'reload', 'controlledbreathing', 'apammo', 'hpammo'],
        'issues_display' => ['Vol. 1 : Damage', 'Vol. 2 : Crippling Shot', 'Vol. 3 : Head Shot', 'Vol. 4 : Unknown', 'Vol. 5 : Controlled Breathing', 'Vol. 6 : Armor Piercing Ammunition', 'Vol. 7 : Hollow Point Ammunition']
        },
        'spearhunter' => {
        'display_name' => "Spear Hunter",
        'image_name' => 'spearhunter.png',
        'issues' => ['1damage', '2maintenance', '3bleed', '4killmove', '5rapidstrike', '6penetratingshaft', '7quickstrike'],
        'issues_display' => ['Vol. 1 : Damage', 'Vol. 2 : Maintenance', 'Vol. 3 : Bleeding Damage', 'Vol. 4 : Kill MOve', 'Vol. 5 : Rapid Strike', 'Vol. 6 : Penetrating Shaft', 'Vol. 7 : Deadly Combat']
        },
        'urbancombat' => {
        'display_name' => "Urban Combat",
        'image_name' => 'urbancombat.png',
        'issues' => ['landing', 'cigar', 'sneaking', 'jumping', 'landmines', 'adrenalinerush', 'roomclearing'],
        'issues_display' => ['Vol. 1 : Military Stealth Boots', 'Vol. 2 : Cigars', 'Vol. 3 : Sneaking', 'Vol. 4 : Jumping', 'Vol. 5 : Land Mines', 'Vol. 6 : Armor Adrenaline Rush', 'Vol. 7 : Room Clearing']
        },
        'techjunkie' => {
        'display_name' => "Tech Junkie",
        'image_name' => 'techjunkie.png',
        'issues' => ['1damage', '2maintenance', '3apammo', '4shells', '5repulsor', '6batoncharge', '7hydraulics'],
        'issues_display' => ['Vol. 1 : Robotic Damage', 'Vol. 2 : Maintenance', 'Vol. 3 : Robotic Turret Ammo', 'Vol. 4 : Turret Shells', 'Vol. 5 : Stun Repulsor Mod', 'Vol. 6 : Charged Strike', 'Vol. 7 : Hydraulics']
        },
        'wastetreasures' => {
        'display_name' => "Wasteland Treasures",
        'image_name' => 'wastetreasures.png',
        'issues' => ['honey', 'coffins', 'acid', 'water', 'doors', 'cloth', 'sinks'],
        'issues_display' => ['Vol. 1 : Honey', 'Vol. 2 : Coffins', 'Vol. 3 : Acid', 'Vol. 4 : Water', 'Vol. 5 : Door Knobs', 'Vol. 6 : Weaving', 'Vol. 7 : Sinks']
        },
    }

    CRAFTING_SKILLS = {
        'harvestingtools' => {
            'display_name' => 'Tools Digest',
            'max_rank' => 100,
            'related_perk' => 'miner69er',
            'team_roles' => ['gatherer'],
        },
        'repairtools' => {
            'display_name' => 'Handy Land',
            'max_rank' => 50,
            'related_perk' => 'advancedengineering',
        },
        'salvagetools' => {
            'display_name' => 'Salvage 4 Fun',
            'max_rank' => 75,
            'related_perk' => 'salvageoperations',
            'team_roles' => ['gatherer'],
        },
        'blades' => {
            'display_name' => 'Knife Guy',
            'max_rank' => 75,
            'related_perk' => 'deepcuts',
        },
        'bows' => {
            'display_name' => 'Bow Hunters',
            'max_rank' => 100,
            'related_perk' => 'archery',
        },
        'explosives' => {
            'display_name' => 'Explosive Magazine',
            'max_rank' => 100,
            'related_perk' => 'demolitionsexpert',
        },
        'robotics' => {
            'display_name' => 'Tech Planet',
            'max_rank' => 100,
        },
        'medical' => {
            'display_name' => 'Medical Journal',
            'max_rank' => 75,
            'related_perk' => 'physician',
            'team_roles' => ['healer'],
        },
        'seeds' => {
            'display_name' => 'Southern Farming',
            'max_rank' => 20,
            'related_perk' => 'livingofftheland',
            'team_roles' => ['food supply'],
        },
        'electrician' => {
            'display_name' => 'Wiring 101',
            'max_rank' => 75,
            'related_perk' => 'advancedengineering',
            'team_roles' => ['base defense'],
        },
        'traps' => {
            'display_name' => 'Electrical Traps',
            'max_rank' => 75,
            'related_perk' => 'advancedengineering',
            'team_roles' => ['base defense'],
        },
        'workstations' => {
            'display_name' => 'Forge Ahead',
            'max_rank' => 75,
            'related_perk' => 'advancedengineering',
            'team_roles' => ['tech'],
        },
        'vehicles' => {
            'display_name' => 'Vehicle Adventures',
            'max_rank' => 100,
            'related_perk' => 'greasemonkey',
            'team_roles' => ['tech'],
        },
        'knuckles' => {
            'display_name' => 'Furious Fist',
            'max_rank' => 75,
            'related_perk' => 'thebrawler',
        },
        'clubs' => {
            'display_name' => 'Big Hitters',
            'max_rank' => 75,
            'related_perk' => 'pummelpete',
        },
        'sledgehammers' => {
            'display_name' => 'Get Hammered',
            'max_rank' => 75,
            'related_perk' => 'skullcrusher',
        },
        'machineguns' => {
            'display_name' => 'Tactical Warfare',
            'max_rank' => 100,
            'related_perk' => 'machinegunner',
        },
        'spears' => {
            'display_name' => 'Sharp Sticks',
            'max_rank' => 75,
            'related_perk' => 'spearmaster',
        },
        'handguns' => {
            'display_name' => 'Handgun Magazine',
            'max_rank' => 100,
            'related_perk' => 'gunslinger',
        },
        'shotguns' => {
            'display_name' => 'Shotgun Weekly',
            'max_rank' => 100,
            'related_perk' => 'boomstick',
        },
        'rifles' => {
            'display_name' => 'Rifle World',
            'max_rank' => 100,
            'related_perk' => 'deadeye',
        },
        'armor' => {
            'display_name' => 'Armored Up',
            'max_rank' => 100,
            'related_perk' => 'heavyarmor',
            'team_roles' => ['armorer'],
        },
        'food' => {
            'display_name' => 'Home Cooking Weekly',
            'max_rank' => 100,
            'related_perk' => 'masterchef',
            'team_roles' => ['food supply'],
        },
    }

    def initialize(players, in_game_days = nil, in_game_hours = nil, server_config = nil)
        @players = players
        @in_game_days = in_game_days
        @in_game_hours = in_game_hours
        @server_config = server_config
    end

    def issue_wanted_by(serie, issue)
        @players.find_all { |p| !p.has_read_issue?(serie, issue) }.sort_by { |player| [player.wants_perk?(serie), player.name] }
    end

    def issue_done?(serie, issue)
        @players.all? { |p| p.has_read_issue?(serie, issue) }
    end

    def series_done?(serie)
        @players.all? { |p| p.has_completed_perk_serie?(serie) }
    end

    def completed_perks
        completed_perks = SevenDaysParty::PERK_MAGAZINES.find_all { |p, _| series_done?(p) }.sort{ |(_, p1), (_, p2)| p1["display_name"] <=> p2["display_name"] }
        completed_perks
    end

    def incomplete_perks
        SevenDaysParty::PERK_MAGAZINES.find_all { |p, _| !series_done?(p) }&.sort{ |(_, p1), (_, p2)| p1["display_name"] <=> p2["display_name"]}
    end

    def perk_magazines_reference
        return SevenDaysParty::PERK_MAGAZINES
    end

    def crafting_skills_reference(skill)
        return SevenDaysParty::CRAFTING_SKILLS[skill]
    end

    def crafting_skills_leader
        @crafting_skills_leader ||= SevenDaysParty::CRAFTING_SKILLS.map { |s, _| [s, crafting_leader(s)] }.to_h
    end

    def all_crafting_skills_completed(player)
        return SevenDaysParty::CRAFTING_SKILLS.find_all { |s, details| crafting_completed?(player, s) }
    end

    def all_magazines_completed(player)
        SevenDaysParty::PERK_MAGAZINES.find_all { |s, _| player.has_completed_perk_serie?(s) }
    end

    def crafting_completed?(player, skill)
        return false if player.crafting_skills[skill].nil?
        return player.crafting_skills[skill] >= SevenDaysParty::CRAFTING_SKILLS[skill]['max_rank']
    end

    def player_crafting_leader_in(player)
        crafting_skills_leader.find_all{ |_, p| p == player }
    end

    def crafting_leader(skill)
        crafters = @players.find_all { |p| !p.crafting_skills[skill].nil? && p.crafting_skills[skill] > 0 && !crafting_completed?(p, skill) }
        return nil if crafters.empty?
        return crafters.sort { |p1, p2| p2.crafting_skills[skill] <=> p1.crafting_skills[skill] }[0]
    end

    def get_binding
        binding
    end
end
