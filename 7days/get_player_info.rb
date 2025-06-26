require 'pathname'
require 'optparse'
require 'logger'
require 'erb'

require './binary_file_reader'
require './erb_renderer'
require './seven_days_party'
require './seven_days_player'

@logger ||= Logger.new(STDOUT)
@logger.level = Logger::WARN

params = {
  :'player-save-files-path' => './',
  :'output-path' => './players.html'
}

OptionParser.new do |opts|
  opts.on('-p PATH', '--player-files-path PATH', 'path to player files *.ttp. Defaults to current directory') do |p|
    params[:'player-save-files-path'] = p
  end
  opts.on('-o PATH', '--output-path PATH', 'path to render the HTML version of the players. default is ./players.html') do |p|
    params[:'output-path'] = p
  end
end.parse!(into: params)

players = []
Dir.glob(File.join(params[:'player-save-files-path'], '*.ttp')).each do |player_save_file|
  players << SevenDaysPlayer.from_file(player_save_file)
end

party = SevenDaysParty.new(players)

open(params[:'output-path'], 'w') do |f|
  f << ErbRenderer.new.render_template('party_view', party: party)
end
