require 'pathname'
require 'optparse'
require 'logger'
require 'erb'

require_relative './binary_file_reader'
require_relative './erb_renderer'
require_relative './seven_days_party'
require_relative './seven_days_player'

@logger ||= Logger.new(STDOUT)
@logger.level = Logger::WARN

params = {
  :'player-save-files-path' => './',
  :'output-path' => './players.html',
  :'server-address' => nil,
  :'telnet-port' => nil
}

OptionParser.new do |opts|
  opts.on('-p PATH', '--player-files-path PATH', 'path to player files *.ttp. Defaults to current directory') do |p|
    params[:'player-save-files-path'] = p
  end
  opts.on('-o PATH', '--output-path PATH', 'path to render the HTML version of the players. default is ./players.html') do |p|
    params[:'output-path'] = p
  end
  opts.on('-a SERVER_ADDRESS', '--server-address SERVER_ADDRESS', 'address of the server. Will try to telnet to it to read the Current Day tag if it is set') do |p|
    params[:'server-address'] = p
  end
  opts.on('-t TELNET_PORT', '--telnet-port TELNET_PORT', 'required when setting the server address to telnet to it') do |p|
    params[:'telnet-port'] = p
  end
end.parse!(into: params)

players = []
Dir.glob(File.join(params[:'player-save-files-path'], '*.ttp')).each do |player_save_file|
  players << SevenDaysPlayer.from_file(player_save_file)
end

def parse_telnet_server_config(telnet_output)
  results = {}
  stats = %w(BlockDamagePlayer BlockDamageAI BlockDamageAIBM XPMultiplier DayNightLength DayLightLength EnemyDifficulty ZombieFeralSense ZombieMove ZombieMoveNight ZombieFeralMove ZombieBMMove BloodMoonFrequency BloodMoonRange BloodMoonWarning BloodMoonEnemyCount LootAbundance LootRespawnDays AirDropFrequency)
  stats.each do |stat|
    matches = telnet_output.match(/#{stat}:(\d+);/)
    if matches
      results[stat] = matches[1].to_i
    end
  end
  results
end

game_days = nil
game_hours = nil
server_config = nil
if params[:'server-address'] && params[:'telnet-port']
  pp "trying to read server config via telnet: #{params[:'server-address']} #{params[:'telnet-port']}"
  telnet_output = `telnet #{params[:'server-address']} #{params[:'telnet-port']}`
  if (matches = telnet_output.match(/CurrentServerTime:(\d+);/))
    server_in_game_days = matches[1].to_i
    game_days = server_in_game_days / 21240 # TODO calculate the proper DIVISOR but this should be roughly accurate
    game_hours = (server_in_game_days % 21240) / 885 # TODO calculate the proper DIVISOR but this should be roughly accurate
    pp "found server at game time #{server_in_game_days}"
  end
  server_config = parse_telnet_server_config(telnet_output)
end


party = SevenDaysParty.new(players, game_days, game_hours, server_config)

open(params[:'output-path'], 'w') do |f|
  f << ErbRenderer.new.render_template('party_view', party: party)
end
