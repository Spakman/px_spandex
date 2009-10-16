require "rubygems"
require "test/unit"
require_relative "../lib/list"

class ListTest < Test::Unit::TestCase
  def setup
    items = %w( Artists Genres Playlists )
    @list = List.new items
  end

  def test_selected
    assert_equal "Artists", @list.selected
  end

  def test_select_next
    assert_equal "Genres", @list.select_next
    assert_equal "Genres", @list.selected
  end

  def test_select_next_last_item_wraps_around
    @list.instance_eval "@selected_index = 2"
    assert_equal "Artists", @list.select_next
    assert_equal "Artists", @list.selected
  end

  def test_select_previous
    @list.instance_eval "@selected_index = 2"
    assert_equal "Genres", @list.select_previous
    assert_equal "Genres", @list.selected
  end

  def test_select_previous_first_item_wraps_around
    assert_equal "Playlists", @list.select_previous
    assert_equal "Playlists", @list.selected
  end

  def test_to_s
    @list.instance_eval "@selected_index = 1"
    expected = <<-LIST
<list>
  <item>Artists</item>
  <item selected="yes">Genres</item>
  <item>Playlists</item>
</list>
LIST
    assert_equal expected, @list.to_s
  end
end
