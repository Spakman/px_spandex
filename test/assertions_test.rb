require "test/unit"
require "fileutils"
require_relative "../lib/assertions"

module Spandex::AssertionsTest
  class TestCard < Spandex::Card
    def show; end
  end

  class SecondTestCard < Spandex::Card
    def show; end
  end

  class TestApplication < Spandex::Application
    attr_accessor :cards, :socket
    entry_point TestCard
  end
end

class AssertionsTest < Test::Unit::CardTestCase
  def setup
    @socket_string = ""
    FileUtils.rm_f "/tmp/#{File.basename($0)}.socket"
    @server = UNIXServer.open "/tmp/#{File.basename($0)}.socket"
    @application = Spandex::AssertionsTest::TestApplication.new
    @application.cards = [ Spandex::AssertionsTest::TestCard.new(@application) ]
    @application.socket = @socket_string
  end

  def teardown
    @server.close unless @server.closed?
    FileUtils.rm_f "/tmp/#{File.basename($0)}.socket"
  end

  # Tests that an assertion passes.
  def assert_assertion(&block)
    begin
      yield
    rescue MiniTest::Assertion => exception
      raise MiniTest::Assertion.new("Assertion failed, but should have passed.")
    end
  end

  # Tests that an assertion fails. Returns the exception that was thrown (if it was).
  def refute_assertion(&block)
    begin
      yield
    rescue MiniTest::Assertion => exception
      return exception
    end
    raise MiniTest::Assertion.new("Assertion should have failed, but did not.")
  end

  def test_setup_card_test
    # since the setup method here basically does the same as
    # setup_card_test, let's first undo that stuff
    @socket_string = nil
    teardown
    @application = nil
    # now perform the test
    setup_card_test Spandex::AssertionsTest::TestCard
    assert_empty @socket_string
    assert_kind_of TestApplication, @application
    assert_kind_of Spandex::AssertionsTest::TestCard, @card
    assert_equal [ @card ], @application.cards
  end

  def test_rendered
    @socket_string = "<render 21>\n<title>Hello!</title>"
    assert_equal "<title>Hello!</title>", rendered
  end

  def test_assert_card_without_params
    assert_assertion { assert_card Spandex::AssertionsTest::TestCard }

    failure = refute_assertion { assert_card Spandex::AssertionsTest::SecondTestCard }
    assert_equal "<Spandex::AssertionsTest::TestCard> expected but was\n<Spandex::AssertionsTest::SecondTestCard>.", failure.message

    assert_raises(NameError) { assert_card WrongCard }
  end

  def test_assert_card_with_params
    @application.cards.last.params = { this_should_be: 999, order: 555 }

    assert_assertion do
      assert_card Spandex::AssertionsTest::TestCard, this_should_be: 999, order: 555
    end

    assert_assertion do
      assert_card Spandex::AssertionsTest::TestCard, order: 555, this_should_be: 999
    end

    failure = refute_assertion do
      assert_card Spandex::AssertionsTest::TestCard, this_should_be: 111
    end
    assert_equal "Expected card params to be {:this_should_be=>111}, but they were {:this_should_be=>999, :order=>555}.", failure.message
  end

  def test_assert_pass_focus_without_params
    failure = refute_assertion { assert_pass_focus }
    assert_equal "Expected focus to be passed, but no response was sent.", failure.message
    @application.cards.last.respond_pass_focus
    assert_assertion { assert_pass_focus }
  end

  def test_assert_pass_focus_expecting_params
    @application.cards.last.respond_pass_focus
    assert_assertion { assert_pass_focus }

    failure = refute_assertion do
      assert_pass_focus application: "boom", method: "kerchow"
    end
    assert_equal "Expected passfocus to be passed '{:application=>\"boom\", :method=>\"kerchow\"}' but it was not passed any.", failure.message
  end

  def test_assert_pass_focus_passing_application
    @application.cards.last.respond_pass_focus application: "mozart"
    assert_assertion { assert_pass_focus }
    assert_assertion do
      assert_pass_focus application: "mozart"
    end
    failure = refute_assertion do
      assert_pass_focus application: "messier"
    end
    assert_equal "Expected passfocus to be supplied with\n'{:application=>\"messier\"}' but it was supplied with\n'{:application=>\"mozart\"}'.", failure.message
  end

  def test_assert_pass_focus_passing_application_and_method
    @application.cards.last.respond_pass_focus application: "mozart", method: "queue_ids"
    assert_assertion { assert_pass_focus }
    assert_assertion do
      assert_pass_focus method: "queue_ids", application: "mozart"
    end
    failure = refute_assertion do
      assert_pass_focus application: "messier", method: "queue_ids"
    end
    assert_equal "Expected passfocus to be supplied with\n'{:application=>\"messier\", :method=>\"queue_ids\"}' but it was supplied with\n'{:application=>\"mozart\", :method=>\"queue_ids\"}'.", failure.message
  end

  def test_assert_button_label
    @socket_string = <<XML
<button position="top_left">top left</button>
<button position="top_right">top right</button>
<button position="bottom_left">bottom left</button>
<button position="bottom_right">bottom right</button>
XML
    assert_assertion do
      assert_button_label :top_left, "top left"
      assert_button_label :top_right, "top right"
      assert_button_label :bottom_left, "bottom left"
      assert_button_label :bottom_right, "bottom right"
    end
    refute_assertion do
      assert_button_label :top_left, "not top left"
      assert_button_label :top_right, "not top right"
      assert_button_label :bottom_left, "not bottom left"
      assert_button_label :bottom_right, "not bottom right"
    end
  end

  def test_assert_text
    @socket_string = <<XML
<button position="top_left">Back</button>
<text>Hello there</text>
<text>Goodbye</text>
<nottext>Nothing to see here</text>
XML
    assert_assertion do
      assert_text "Hello there"
      assert_text "Goodbye"
    end
    refute_assertion do
      assert_text "Hello"
      assert_text "there"
      assert_text "Back"
      assert_text "Nothing to see here"
    end
  end

  def test_assert_text_escapes_regex_characters
    @socket_string = <<XML
<text>Hello/Goodbye</text>
XML
    assert_assertion do
      assert_text "Hello/Goodbye"
    end
    refute_assertion do
      assert_text "Hello.Goodbye"
    end
  end
end
