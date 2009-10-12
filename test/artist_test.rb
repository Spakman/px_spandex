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
    assert_equal Artist.new(artist: "Nirvana"), Artist.new(artist: "Nirvana")
  end

  def test_get
    artist = Artist.get("Nirvana")
    assert_equal "Nirvana", artist.name
  end

  def test_all_alphabetical
    assert_equal [ Artist.get("Nirvana"), Artist.get("Pendulum") ], Artist.all
    assert_not_equal [ Artist.get("Pendulum"), Artist.get("Nirvana") ], Artist.all
  end

  def test_albums_alphabetical
    assert_equal 1, Artist.get("Pendulum").albums.length
    assert_equal "Hold Your Colour", Artist.get("Pendulum").albums.first.name
  end
end
