# Copyright (C) 2009 Mark Somerville <mark@scottishclimbs.com>
# Released under the General Public License (GPL) version 3.
# See COPYING

$LOAD_PATH.unshift "#{ENV["PROJECT_X_BASE"]}/lib/"
require "honcho/message"
require_relative "application"
require_relative "card"
require_relative "list"

class Spandex::Card
  def ==(object)
    if object.kind_of? Spandex::Card
      self.class == object.class
    else
      false
    end
  end
end

class Spandex::ListCard < Spandex::Card
  attr_reader :list
end

class Spandex::List
  attr_reader :items
  attr_accessor :selected_index
end

class TestApplication < Spandex::Application
  attr_reader :cards
end

class Test::Unit::CardTestCase < Test::Unit::TestCase
  def setup_card_test(card)
    TestApplication.entry_point card
    @socket_string = ""
    FileUtils.rm_f "/tmp/#{File.basename($0)}.socket"
    UNIXServer.open "/tmp/#{File.basename($0)}.socket"
    @application = TestApplication.new
    @card = card.new @socket_string, @application
  end

  def rendered
    @socket_string.sub /^<render \d+>\n/, ""
  end

  def assert_card(card, params = nil)
    message = "Expected active Card to be #{card}, but it was #{@application.cards.last}"
    assert_equal @application.cards.last.class, card

    if params
      message = "Expected card params to be #{params}, but they were #{@application.cards.last.params}."
      assert @application.cards.last.params == params, message
    end
  end

  def assert_pass_focus(options = {})
    if @socket_string =~ /^<(\w+) \d+>\n(.+)?$/m
      type = $1
      body = $2
      message = Honcho::Message.new type, body

      error = "Expected focus to be passed, but it was not"
      assert(message.type == :passfocus, error)

      if not options.empty?
        if message.body
          error = "Expected passfocus to be supplied with\n'#{options}' but it was supplied with\n'#{message.body}'."
          assert(message.body["application"] == options[:application], error)
        else
          flunk "Expected focus to be passed to '#{options[:application]}' but it was not passed an application"
        end
      end
    else
      flunk "Expected focus to be passed, but it was not."
    end
  end
end
