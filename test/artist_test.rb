require "rubygems"
require "rufus/tokyo"
require "test/unit"
require "#{File.dirname(__FILE__)}/test_helper"
require "#{File.dirname(__FILE__)}/../lib/artist"

class ArtistTest < Test::Unit::TestCase
  def setup
    setup_data
  end

  def teardown
    FileUtils.rm_f TABLE_FILEPATH
  end

  def test_eql
    assert_equal Messier::Artist.new(artist: "Nirvana"), Messier::Artist.new(artist: "Nirvana")
  end

  def test_get
    artist = Messier::Artist.get("Nirvana")
    assert_equal "Nirvana", artist.name
  end

  def test_all_alphabetical
    assert_equal [ Messier::Artist.get("Nirvana"), Messier::Artist.get("Pendulum") ], Messier::Artist.all
    assert_not_equal [ Messier::Artist.get("Pendulum"), Messier::Artist.get("Nirvana") ], Messier::Artist.all
  end

  def test_albums_alphabetical
    assert_equal 1, Messier::Artist.get("Pendulum").albums.length
    assert_equal "Hold Your Colour", Messier::Artist.get("Pendulum").albums.first.name
  end
end
