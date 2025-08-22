require 'httparty'
require 'json'
require 'fileutils'
require 'logger'

require './character_klass'
require './scraper'
require './character_klass_levels'
require './character_sheet'
require './console_writer'
require './spell_list'
require './spell_source'
require './spell'
require './spellbook'

class Main
  class << self
    def port_de_lorque
      if @port_de_lorque_players.nil? || @port_de_lorque_players.empty?
        @port_de_lorque_players = []
        spells_sans_croc = ['Creation', 'Absorb Elements', 'Chill Touch', 'Enhance Ability', 'Hypnotic Pattern', 'Invisibility',
                            'Mage Hand', 'Mending', 'Message', 'Prestidigitation', 'Sacred Flame', 'Shape Water', 'Silent Image', 'Tasha’s Caustic Brew', 'Vortex Warp', 'Dimension Door']

        @port_de_lorque_players << CharacterSheet.new(char_name: 'Sans-croc', player_name: 'Louis V.',
                                      klass_levels: [CharacterKlassLevel.sorcerer_lunar(level: 7, choices: { spells: spells_sans_croc })], source: 'XPHB', str: 8, dex: 17, con: 14, int: 10, wis: 10, cha: 18, learned_spells: spells_sans_croc)
        @port_de_lorque_players << CharacterSheet.new(char_name: 'Florianz', player_name: 'Francis M.',
                                      klass_levels: [CharacterKlassLevel.cleric_trickery(level: 7)], source: 'XPHB', str: 8, dex: 17, con: 14, int: 10, wis: 10, cha: 18, learned_spells: [])
        @port_de_lorque_players << CharacterSheet.new(char_name: 'Alfonso', player_name: 'Olivier P.',
                                      klass_levels: [CharacterKlassLevel.artificer_battle_smith(level: 7, source: 'TCE')], source: 'XPHB', str: 8, dex: 17, con: 14, int: 10, wis: 10, cha: 18, learned_spells: [])
        @port_de_lorque_players << CharacterSheet.new(char_name: 'Guillemain', player_name: 'Maxime T.',
                                      klass_levels: [CharacterKlassLevel.rogue_assassin(level: 7)], source: 'XPHB', str: 8, dex: 17, con: 14, int: 10, wis: 10, cha: 18, learned_spells: [])
        @port_de_lorque_players << CharacterSheet.new(char_name: 'Clovis', player_name: 'David R.',
                                      klass_levels: [CharacterKlassLevel.ranger_gloom_stalker(level: 7)], source: 'XPHB', str: 8, dex: 17, con: 14, int: 10, wis: 10, cha: 18, learned_spells: [])
        @port_de_lorque_players << CharacterSheet.new(char_name: 'Tobiash', player_name: 'Alex G.',
                                      klass_levels: [CharacterKlassLevel.barbarian_world_tree(level: 7)], source: 'XPHB', str: 8, dex: 17, con: 14, int: 10, wis: 10, cha: 18, learned_spells: [])
        @port_de_lorque_players << CharacterSheet.new(char_name: 'Ando', player_name: 'David B.',
                                      klass_levels: [CharacterKlassLevel.monk_shadow(level: 7)], source: 'XPHB', str: 8, dex: 17, con: 14, int: 10, wis: 10, cha: 18, learned_spells: [])
        @port_de_lorque_players << CharacterSheet.new(char_name: 'Godefroy', player_name: 'Julien G.',
                                    klass_levels: [CharacterKlassLevel.paladin_glory(level: 7)], source: 'XPHB', str: 8, dex: 17, con: 14, int: 10, wis: 10, cha: 18, learned_spells: [])
      end
      return @port_de_lorque_players
    end

    def print_port_de_lorque
      writer = ConsoleWriter.new
      port_de_lorque.each do |player|
        writer.write("<#{'-' * 78}>")
        writer.with_nesting do
          player.print_summary(writer)
        end
      end
    end
  end
end
