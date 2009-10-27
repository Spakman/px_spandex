require "rubygems"
require "test/unit"
require_relative "../lib/list"

class List
  attr_reader :starting_item
  remove_const :NUMBER_OF_LIST_ITEMS_TO_DISPLAY
  NUMBER_OF_LIST_ITEMS_TO_DISPLAY = 3
end

class ListTest < Test::Unit::TestCase
  def setup
    items = %w( Artists Genres Popular Latest Never Playlists )
    @list = List.new items
  end

  def test_selected
    assert_equal "Artists", @list.selected
    assert_equal 0, @list.starting_item
  end

  def test_select_next
    assert_equal "Genres", @list.select_next
    assert_equal "Genres", @list.selected
    assert_equal 0, @list.starting_item
  end

  def test_select_next_starting_2_selected_2
    @list.instance_eval "@starting_item = 2"
    @list.instance_eval "@selected_index = 2"
    assert_equal "Latest", @list.select_next
    assert_equal "Latest", @list.selected
    assert_equal 2, @list.starting_item
  end

  def test_selected_to_end
    @list.instance_eval "@selected_index = 3"
    assert_equal %w( Latest Never Playlists ), @list.selected_to_end
  end

  def test_select_next_incrementing_starting_index
    @list.instance_eval "@selected_index = 2"
    assert_equal "Latest", @list.select_next
    assert_equal "Latest", @list.selected
    assert_equal 1, @list.starting_item

    assert_equal "Never", @list.select_next
    assert_equal "Never", @list.selected
    assert_equal 2, @list.starting_item

    assert_equal "Playlists", @list.select_next
    assert_equal "Playlists", @list.selected
    assert_equal 3, @list.starting_item
  end

  def test_select_next_last_item_does_not_change
    @list.instance_eval "@starting_item = 3"
    @list.instance_eval "@selected_index = 5"
    assert_equal "Playlists", @list.select_next
    assert_equal "Playlists", @list.selected
    assert_equal 3, @list.starting_item
  end

  def test_select_previous
    @list.instance_eval "@selected_index = 2"
    assert_equal "Genres", @list.select_previous
    assert_equal "Genres", @list.selected
  end

  def test_select_previous_first_item_does_not_change
    assert_equal "Artists", @list.select_previous
    assert_equal "Artists", @list.selected
  end

  def test_select_previous_starting_2_selected_4
    @list.instance_eval "@starting_item = 2"
    @list.instance_eval "@selected_index = 4"
    assert_equal "Latest", @list.select_previous
    assert_equal "Latest", @list.selected
    assert_equal 2, @list.starting_item
  end

  def test_select_previous_decrementing_starting_index
    @list.instance_eval "@starting_item = 3"
    @list.instance_eval "@selected_index = 5"
    assert_equal "Never", @list.select_previous
    assert_equal "Never", @list.selected
    assert_equal 3, @list.starting_item

    assert_equal "Latest", @list.select_previous
    assert_equal "Latest", @list.selected
    assert_equal 3, @list.starting_item

    assert_equal "Popular", @list.select_previous
    assert_equal "Popular", @list.selected
    assert_equal 2, @list.starting_item

    assert_equal "Genres", @list.select_previous
    assert_equal "Genres", @list.selected
    assert_equal 1, @list.starting_item

    assert_equal "Artists", @list.select_previous
    assert_equal "Artists", @list.selected
    assert_equal 0, @list.starting_item

    assert_equal "Artists", @list.select_previous
    assert_equal "Artists", @list.selected
    assert_equal 0, @list.starting_item
  end

  def test_to_s_starting_at_zero
    @list.instance_eval "@selected_index = 1"
    expected = <<-LIST
<list>
  <item>Artists</item>
  <item selected="yes">Genres</item>
  <item>Popular</item>
</list>
LIST
    assert_equal expected, @list.to_s
  end

  def test_to_s_starting_at_one
    @list.instance_eval "@selected_index = 1"
    @list.instance_eval "@starting_item = 1"
    expected = <<-LIST
<list>
  <item selected="yes">Genres</item>
  <item>Popular</item>
  <item>Latest</item>
</list>
LIST
    assert_equal expected, @list.to_s
  end
end
