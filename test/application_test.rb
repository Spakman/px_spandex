require_relative "test_helper"
require_relative "../lib/application"

Thread.abort_on_exception = true

module Kernel
  def exit
    begin
      ApplicationTest.send :remove_method, :exit_called?
    rescue NameError
    end
    ApplicationTest.send :define_method, "exit_called?" do
      true
    end
  end
end

class MyCard
  attr_accessor :params, :responded
  attr_reader :show_called, :messages_received
  def initialize(application)
    @show_called = 0
    @messages_received = []
  end

  def show
    @show_called += 1
  end

  def receive_message(message)
    @messages_received << message
  end
end

class MySecondCard < MyCard; end
class MyThirdCard < MyCard; end

class TestApplication < Spandex::Application
  attr_accessor :cards, :has_focus, :stop_rendering_called
  attr_reader :socket, :cards_cache, :fib
  entry_point MyCard

  def stop_rendering
    @stop_rendering_called = true
  end
end

class BackgroundTestApplication < Spandex::Application
  attr_reader :cards, :socket
  entry_point MyCard
  can_run_in_background
end

class Spandex::Cache
  attr_reader :cache
  def size
    @cache.size
  end
end

class ApplicationTest < Test::Unit::TestCase
  def setup
    @socket_path = "/tmp/#{File.basename($0)}.socket"
    FileUtils.rm_f @socket_path
    @listening_socket = UNIXServer.open @socket_path
    @listening_socket.listen 1
    Thread.new do
      @socket = @listening_socket.accept
    end
    @application = TestApplication.new
    begin
      self.class.send :remove_method, :exit_called?
    rescue NameError
    end

    self.class.send :define_method, "exit_called?" do
      false
    end
  end

  def teardown
    @socket.close if defined? @socket and not @socket.closed?
    FileUtils.rm_f @socket_path
  end

  def test_entry_point
    assert_equal MyCard, @application.entry_point
    assert_equal 1, @application.cards.length
    assert_instance_of MyCard, @application.cards.last
    assert_equal 1, @application.cards.last.show_called
  end

  def test_load_card_without_params
    @application.load_card MySecondCard
    assert_equal 2, @application.cards.length
    assert_instance_of MySecondCard, @application.cards.last
    assert_equal 1, @application.cards.last.show_called
    assert_nil @application.cards.last.params
    assert @application.stop_rendering_called
  end

  def test_load_card_with_params
    @application.load_card MySecondCard, 123
    assert_equal 2, @application.cards.length
    assert_instance_of MySecondCard, @application.cards.last
    assert_equal 1, @application.cards.last.show_called
    assert_equal 123, @application.cards.last.params
    assert @application.stop_rendering_called
  end

  def test_cards_are_cached_based_on_card_stack
    second_card = @application.load_card MySecondCard
    assert_equal 2, @application.cards_cache.size
    third_card = @application.load_card MyThirdCard
    assert_equal 3, @application.cards_cache.size

    # Now let's reset the card stack and load the third card again.
    # This should be a *different* instance of the third card, since
    # the stack 'leading' to it is different (there is no MySecondCard
    # this time).
    @application.cards = [ @application.cards.first ]
    refute_equal third_card, @application.load_card(MyThirdCard)
    assert_equal 4, @application.cards_cache.size

    # Reset and make sure we get a cache hit when loading MySecondCard.
    @application.cards = [ @application.cards.first ]
    assert_equal second_card, @application.load_card(MySecondCard)
    assert_equal 4, @application.cards_cache.size
  end

  def test_previous_card
    card = @application.load_card MySecondCard
    @application.previous_card
    assert_equal 1, @application.cards.length
    assert_instance_of MyCard, @application.cards.last
    assert_equal 2, @application.cards.last.show_called
    assert @application.stop_rendering_called
  end

  def test_previous_card_with_no_cards_left
    card = @application.cards.first
    @application.previous_card
    sleep 0.2
    assert_equal "<closing 0>\n", @socket.read
    assert @application.stop_rendering_called
    assert exit_called?
  end

  def test_previous_card_with_no_cards_left_and_can_run_in_background
    card = @application.cards.first
    @application.class.class_eval "can_run_in_background"
    @application.previous_card
    sleep 0.2
    assert_equal "<passfocus 0>\n", @socket.read(14)
    assert @application.stop_rendering_called
    refute exit_called?
  end

  def test_run
    Thread.new do
      @application.run
    end
    sleep 0.2
    @socket << "<inputevent 8>\ntop_left"; sleep 0.2
    assert_equal 1, @application.cards.last.messages_received.length

    @application.load_card MySecondCard
    @socket << "<inputevent 8>\ntop_left"; sleep 0.2
    assert_equal 1, @application.cards.last.messages_received.length
  end

  def test_keeps_track_of_focus_state
    Thread.new do
      @application.run
    end
    sleep 0.2
    refute @application.has_focus
    @socket << "<havefocus 0>\n"; sleep 0.2
    assert @application.has_focus
    @application.has_focus = false
    refute @application.has_focus
  end

  def test_render_markup
    Thread.new do
      @application.run
    end
    sleep 0.2
    @socket << "<havefocus 0>\n"; sleep 0.2

    @application.render @application.cards.last, "<text>hello</text>"
    assert_equal "<render 18>\n<text>hello</text>", @socket.read(30)
  end

  def test_render_block
    Thread.new do
      @application.run
    end
    sleep 0.2
    @socket << "<havefocus 0>\n"; sleep 0.2

    @application.render @application.cards.last do
      "<text>hello</text>"
    end
    assert_equal "<render 18>\n<text>hello</text>", @socket.read(30)
  end

  def test_render_without_markup_or_block
    Thread.new do
      @application.run
    end
    sleep 0.2
    @socket << "<havefocus 0>\n"; sleep 0.2

    assert_raises(RuntimeError) { @application.render @application.cards.last }
  end

  def test_render_without_focus_doesnt_do_anything
    @application.render @application.cards.last, "<text>hello</text>"
    sleep 0.2
    assert_nil IO.select([ @socket ], nil, nil, 0.5)
  end

  def test_render_inactive_card_doesnt_do_anything
    @application.load_card MySecondCard
    @application.render @application.cards.first, "<text>hello</text>"
    sleep 0.2
    assert_nil IO.select([ @socket ], nil, nil, 0.5)
  end
end
