require_relative "test_helper"
require_relative "../lib/card"

class TestCard < Spandex::Card
  attr_reader :show_called, :top_left_called, :call_me_called, :call_me_params, :call_me_no_params_called, :lambda_called
  attr_accessor :dynamic

  def initialize(application)
    @show_called = @top_left_called = @call_me_called = @call_me_no_params_called = 0
    super
  end

  def show
    @show_called += 1
  end

  def call_me(params = nil)
    @call_me_called += 1
    @call_me_params = params
  end

  def call_me_no_params
    @call_me_no_params_called += 1
  end
end

class SecondCard < TestCard; end

class FakeApplication
  attr_reader :previous_card_called, :load_card_called, :have_focus, :render_called, :keep_focus_called, :pass_focus_called

  def initialize
    @have_focus = true
    @render_called = 0
    @keep_focus_called = 0
    @pass_focus_called = 0
  end

  def render(card, markup = nil, &block)
    @render_called += 1
  end

  def respond_keep_focus
    @keep_focus_called += 1
  end

  def respond_pass_focus(options = nil)
    @pass_focus_called += 1
  end

  def previous_card
    @previous_card_called = 1
  end

  def load_card(klass, params = nil)
    @load_card_called = [ klass, params ]
    if klass
      klass.new(nil)
    else
      @load_card_called
    end
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
    @card = TestCard.new @application
  end

  def teardown
    TestCard.send(:remove_method, :top_left) rescue NameError
    TestCard.send(:remove_method, :top_right) rescue NameError
  end

  def test_respond_keep_focus
    @card.respond_keep_focus
    assert @application.keep_focus_called
  end

  def test_pass_focus
    @card.respond_pass_focus
    assert @application.pass_focus_called
  end

  def test_render
    @card.render "<text>this is some markup</text>"
    assert_equal 1, @application.render_called
  end

  def test_render_every
    @card.render_every(1) { "<text>Go!</text>" }
    sleep 1.5
    assert_equal 2, @application.render_called
  end

  def test_receive_havefocus_message
    @card.receive_message Honcho::Message.new(:havefocus, nil) 
    assert_equal 1, @card.show_called
  end

  def test_button_handler_goes_to_previous_card
    TestCard.top_left :back
    @card = TestCard.new @application
    assert @card.methods.include? :top_left
    @card.top_left
    assert_equal 1, @application.previous_card_called
  end

  def test_button_handler_goes_to_another_card_without_params
    TestCard.top_right :card => :second_card
    @card = TestCard.new @application
    assert @card.methods.include? :top_right
    @card.top_right
    assert_equal [ SecondCard, nil ], @application.load_card_called
  end

  def test_button_handler_goes_to_another_card_using_classname
    TestCard.top_right :card => SecondCard
    @card = TestCard.new @application
    assert @card.methods.include? :top_right
    @card.top_right
    assert_equal [ SecondCard, nil ], @application.load_card_called
  end

  def test_button_handler_goes_to_another_card_with_params
    TestCard.top_right :card => :second_card, :params => 12
    @card = TestCard.new @application
    assert @card.methods.include? :top_right
    @card.top_right
    assert_equal [ SecondCard, 12 ], @application.load_card_called
  end

  def test_button_handler_goes_to_another_card_with_dynamic_card_name
    TestCard.top_right card: -> { @second_card }
    @card = TestCard.new @application
    @card.instance_eval "@second_card = :second_card"
    @card.top_right
    assert_equal [ SecondCard, nil ], @application.load_card_called
  end

  def test_button_handler_with_dynamic_card_name_uses_instance_context
    TestCard.top_right card: -> { @second_card }
    @card = TestCard.new @application
    @second_card = :second_card
    @card.top_right
    assert_equal [ nil, nil ], @application.load_card_called
  end

  def test_button_handler_goes_to_another_card_with_dynamic_params
    TestCard.top_right :card => :second_card, params: -> { @dynamic }
    @card = TestCard.new @application
    @card.instance_eval "@dynamic = 'this was a lambda'"
    @card.top_right
    assert_equal [ SecondCard, "this was a lambda" ], @application.load_card_called
  end

  def test_button_handler_call_method_in_same_card
    TestCard.top_right :method => :call_me_no_params
    @card = TestCard.new @application
    @card.top_right
    assert_nil @application.load_card_called
    assert_equal 1, @card.call_me_no_params_called
  end

  def test_button_handler_call_method_with_lambda_parameter
    TestCard.top_right method: -> { @lambda_called = "lamb is tasty" }
    @card = TestCard.new @application
    @card.top_right
    assert_equal "lamb is tasty", @card.lambda_called
  end

  def test_button_handler_call_method_with_lambda_parameter_with_parameters
    TestCard.top_right method: ->(v) { @lambda_called = v }, :params => "lamb is tasty"
    @card = TestCard.new @application
    @card.top_right
    assert_equal "lamb is tasty", @card.lambda_called
  end

  def test_button_handler_call_method_with_params
    TestCard.top_right :method => :call_me, params: -> { @dynamic }
    @card = TestCard.new @application
    @card.instance_eval "@dynamic = 'this was a lambda'"
    @card.top_right
    assert_equal 1, @card.call_me_called
    assert_equal "this was a lambda", @card.call_me_params
  end

  def test_load_card
    card = @card.load_card SecondCard
    assert_instance_of SecondCard, card
  end
end
