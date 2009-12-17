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
    attr_accessor :cards
    entry_point TestCard
  end
end

class AssertionsTest < Test::Unit::CardTestCase
  def setup
    @socket_string = ""
    FileUtils.rm_f "/tmp/#{File.basename($0)}.socket"
    UNIXServer.open "/tmp/#{File.basename($0)}.socket"
    @application = Spandex::AssertionsTest::TestApplication.new
    @application.cards = [ Spandex::AssertionsTest::TestCard.new(@socket_string, @application) ]
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
    assert_equal "Expected focus to be passed, but it was not.", failure.message
    @application.cards.last.pass_focus
    assert_assertion { assert_pass_focus }
  end

  def test_assert_pass_focus_expecting_application
    @application.cards.last.pass_focus
    assert_assertion { assert_pass_focus }

    failure = refute_assertion do
      assert_pass_focus application: "boom"
    end
    assert_equal "Expected focus to be passed to 'boom' but it was not passed an application", failure.message
  end

  def test_assert_pass_focus_passing_application
    @application.cards.last.pass_focus application: "mozart"
    assert_assertion { assert_pass_focus }
    assert_assertion do
      assert_pass_focus application: "mozart"
    end
    failure = refute_assertion do
      assert_pass_focus application: "messier"
    end
    assert_equal "Expected passfocus to be supplied with\n'{:application=>\"messier\"}' but it was supplied with\n'{\"application\"=>\"mozart\"}'.", failure.message
  end
end
