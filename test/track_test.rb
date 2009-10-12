require "rubygems"
require "rufus/tokyo"
require "test/unit"
require "#{File.dirname(__FILE__)}/test_helper"
require "#{File.dirname(__FILE__)}/../lib/track"

class TrackTest < Test::Unit::TestCase
  def setup
    setup_data
  end

  def teardown
    FileUtils.rm_f TABLE_FILEPATH
  end

  def test_all
    assert_equal 2, Track.all.length
    assert_equal "In Bloom", Artist.get("Nirvana").albums.first.tracks.first.name
  end

  def test_artist
    track = Artist.get("Nirvana").albums.first.tracks.first
    assert_equal Artist.get("Nirvana"), track.artist
  end

  def test_genre
    track = Artist.get("Nirvana").albums.first.tracks.first
    assert_equal "Grunge", track.genre.name
  end
end
