require "rubygems"
require "rufus/tokyo"
require "test/unit"
require "#{File.dirname(__FILE__)}/test_helper"
require "#{File.dirname(__FILE__)}/../lib/album"

class AlbumTest < Test::Unit::TestCase
  def setup
    setup_data
  end
  
  def teardown
    FileUtils.rm_f TABLE_FILEPATH
  end

  def test_all
    assert_equal 2, Album.all.length
    assert_equal "Hold Your Colour", Album.all.first.name
  end

  def test_artist
    assert_equal Artist.get("Pendulum"), Album.all.first.artist
  end

# def test_tracks
#   assert_equal Artist.get("Pendulum"), Album.all.first.artist
# end
end
