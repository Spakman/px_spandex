$LOAD_PATH.unshift "#{ENV['PROJECT_X_BASE']}/lib/"
require "fileutils"

TABLE_FILEPATH = "#{File.dirname(__FILE__)}/testtable.tct"

def setup_data
  Messier::Model.close_table
  @table = Rufus::Tokyo::Table.new(TABLE_FILEPATH)
  @table['pk0'] = { 'artist' => 'Nirvana', 'album' => 'Nevermind', 'track' => 'In Bloom', 'genre' => 'Grunge' }
  @table['pk1'] = { 'artist' => 'Nirvana', 'album' => 'Nevermind', 'track' => 'Lithium', 'genre' => 'Grunge' }
  @table['pk1'] = { 'artist' => 'Pendulum', 'album' => 'Hold Your Colour', 'track' => 'Slam', 'genre' => 'Drum and bass' }
  @table['pk1'] = { 'artist' => 'Pendulum', 'album' => 'Hold Your Colour', 'track' => 'Another Planet', 'genre' => 'Drum and bass' }
  @table.close
  Messier::Model.open_table
end
