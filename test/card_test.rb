require "test/unit"
require "socket"
require "fileutils"
require "thread"
require "#{File.dirname(__FILE__)}/../lib/card"

class TestCard < Card
  attr_reader :show_called, :top_left_called, :call_me_called, :call_me_params
  attr_accessor :dynamic

  def initialize(socket, application)
    @show_called = @top_left_called = @call_me_called = 0
    super
  end

  def show
    @show_called += 1
  end

  def call_me(params = nil)
    @call_me_called += 1
    @call_me_params = params
  end
end

class SecondCard < TestCard; end

class FakeApplication
  attr_reader :previous_card_called, :load_card_called
  def previous_card
    @previous_card_called = 1
  end

  def load_card(klass, params = nil)
    @load_card_called = [ klass, params ]
  end
end

class FakeSocket
  attr_accessor :bytes_written
  def initialize
    @bytes_written = ""
  end

  def <<(string)
    @bytes_written << string
  end

  def flush; end
end

class CardTest < Test::Unit::TestCase
  def setup
    @application = FakeApplication.new
    @socket = FakeSocket.new
    @card = TestCard.new @socket, @application
  end

  def teardown
    TestCard.send(:remove_method, :top_left) rescue NameError
    TestCard.send(:remove_method, :top_right) rescue NameError
  end

  def test_respond_keep_focus
    @card.respond_keep_focus
    assert_equal "<keepfocus 0>\n", @socket.bytes_written
  end

  def test_render
    @socket.bytes_written = ""
    markup = "<text>this is some markup</text>"
    @card.render markup
    assert_equal "<render #{markup.length}>\n#{markup}", @socket.bytes_written
  end

  def test_receive_havefocus_message
    @card.receive_message Honcho::Message.new(:havefocus, nil) 
    assert_equal 1, @card.show_called
  end

  def test_receive_inputevent_message
    # we haven't defined a top_left method yet, so this should throw an error.
    assert_raises(NoMethodError) { @card.receive_message Honcho::Message.new(:inputevent, "top_left") }
  end

  def test_button_handler_goes_to_previous_card
    TestCard.top_left :back
    @card = TestCard.new @socket, @application
    assert @card.methods.include? :top_left
    @card.top_left
    assert_equal 1, @application.previous_card_called
  end

  def test_button_handler_goes_to_another_card_without_params
    TestCard.top_right :card => :second_card
    @card = TestCard.new @socket, @application
    assert @card.methods.include? :top_right
    @card.top_right
    assert_equal [ SecondCard, nil ], @application.load_card_called
  end

  def test_button_handler_goes_to_another_card_with_params
    TestCard.top_right :card => :second_card, :params => 12
    @card = TestCard.new @socket, @application
    assert @card.methods.include? :top_right
    @card.top_right
    assert_equal [ SecondCard, 12 ], @application.load_card_called
  end

  def test_button_handler_goes_to_another_card_with_dynamic_card_name
    TestCard.top_right card: -> { @second_card }
    @card = TestCard.new @socket, @application
    assert @card.methods.include? :top_right
    @second_card = :second_card
    @card.top_right
    assert_equal [ SecondCard, nil ], @application.load_card_called
  end

  def test_button_handler_goes_to_another_card_with_dynamic_params
    TestCard.top_right :card => :second_card, params: -> { @dynamic }
    @card = TestCard.new @socket, @application
    assert @card.methods.include? :top_right
    @dynamic = "this was a lambda"
    @card.top_right
    assert_equal [ SecondCard, @dynamic ], @application.load_card_called
    @dynamic = "this was another lambda"
    @card.top_right
    assert_equal [ SecondCard, @dynamic ], @application.load_card_called
  end

  def test_button_handler_call_method_in_same_card
    TestCard.top_right :method => :call_me
    @card = TestCard.new @socket, @application
    assert @card.methods.include? :top_right
    @card.top_right
    assert_nil @application.load_card_called
    assert_equal 1, @card.call_me_called
  end

  def test_button_handler_call_method_with_params
    TestCard.top_right :method => :call_me, params: -> { @dynamic }
    @card = TestCard.new @socket, @application
    assert @card.methods.include? :top_right
    @dynamic = "this was a lambda"
    @card.top_right
    assert_nil @application.load_card_called
    assert_equal 1, @card.call_me_called
    assert_equal @dynamic, @card.call_me_params
  end
end
