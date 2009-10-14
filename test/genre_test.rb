require "rubygems"
require "rufus/tokyo"
require "test/unit"
require "#{File.dirname(__FILE__)}/test_helper"
require "#{File.dirname(__FILE__)}/../lib/genre"

class GenreTest < Test::Unit::TestCase
  def setup
    setup_data
  end

  def teardown
    FileUtils.rm_f TABLE_FILEPATH
  end

  def test_all
    assert_equal 2, Messier::Genre.all.length
    assert_equal "Grunge", Messier::Artist.get("Nirvana").albums.first.tracks.first.genre.name
  end

  def test_to_s
    assert_equal "Grunge", Messier::Artist.get("Nirvana").albums.first.tracks.first.genre.to_s
  end
end
