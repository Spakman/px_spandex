require_relative "test_helper"
require_relative "../lib/application"

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
  def initialize(socket, application)
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
  attr_accessor :cards
  attr_reader :socket, :cards_cache
  entry_point MyCard
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
    listening_socket = UNIXServer.open @socket_path
    listening_socket.listen 1
    Thread.new do
      @socket = listening_socket.accept
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
  end

  def test_load_card_with_params
    @application.load_card MySecondCard, 123
    assert_equal 2, @application.cards.length
    assert_instance_of MySecondCard, @application.cards.last
    assert_equal 1, @application.cards.last.show_called
    assert_equal 123, @application.cards.last.params
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
    @application.load_card MySecondCard
    @application.previous_card
    assert_equal 1, @application.cards.length
    assert_instance_of MyCard, @application.cards.last
    assert_equal 2, @application.cards.last.show_called
  end

  def test_previous_card_with_no_cards_left
    @application.previous_card
    sleep 0.2
    assert_equal "<closing 0>\n", @socket.read
    assert exit_called?
  end

  def test_previous_card_with_no_cards_left_and_can_run_in_background
    @application.class.class_eval "can_run_in_background"
    @application.previous_card
    sleep 0.2
    assert_equal "<passfocus 0>\n", @socket.read(14)
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
end
