require_relative "test_helper"
require_relative "../lib/card"

class TestList
  attr_reader :select_previous_called, :select_next_called, :selected_called
  def select_previous
    @select_previous_called = true
  end

  def select_next
    @select_next_called = true
  end

  def selected
    @selected_called = true
    :test_list_card
  end
end

class TestApp
  attr_reader :load_card_called
  def load_card(card, params)
    @load_card_called = true
  end
end

class TestListCard < Spandex::ListCard
  attr_reader :list, :show_called
  def after_initialize
    @list = TestList.new
  end

  def show
    @show_called = true
  end
end

class ListCardTest < Test::Unit::TestCase
  def test_jog_wheel_left_is_defined
    card = TestListCard.new "", TestApp.new
    card.jog_wheel_left
    assert card.show_called
    assert card.list.select_previous_called
  end

  def test_jog_wheel_right_is_defined
    card = TestListCard.new "", TestApp.new
    card.jog_wheel_right
    assert card.show_called
    assert card.list.select_next_called
  end

  def test_jog_wheel_button_is_defined
    card = TestListCard.new "", TestApp.new
    card.jog_wheel_button
    refute card.show_called
    assert card.list.selected
  end
end
