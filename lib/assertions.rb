# Copyright (C) 2009 Mark Somerville <mark@scottishclimbs.com>
# Released under the General Public License (GPL) version 3.
# See COPYING

$LOAD_PATH.unshift "#{ENV["PROJECT_X_BASE"]}/lib/"
require "test/unit"
require "fileutils"
require "honcho/message"
require_relative "application"
require_relative "card"
require_relative "list"

class Spandex::Card
  attr_accessor :socket

  def ==(object)
    if object.kind_of? Spandex::Card
      self.class == object.class
    else
      false
    end
  end

  alias_method :old_render_every, :render_every

  def render_every(seconds, &block)
    render block.call
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
  attr_accessor :has_focus, :socket
end

class Test::Unit::CardTestCase < Test::Unit::TestCase
  def setup_card_test(card)
    TestApplication.entry_point card
    @socket_string = ""
    FileUtils.rm_f "/tmp/#{File.basename($0)}.socket"
    UNIXServer.open "/tmp/#{File.basename($0)}.socket"
    @application = TestApplication.new
    @application.has_focus = true
    @card = @application.cards.last
    @application.socket = @socket_string
  end

  # Returns the rendered string.
  def rendered
    @socket_string.sub /^<render \d+>\n/, ""
  end

  # Checks that the passed card_klass is active and that any supplied
  # parameters were passed.
  def assert_card(card_klass, params = nil)
    message = "Expected active Card to be #{card_klass}, but it was #{@application.cards.last.class}"
    assert(@application.cards.last.class == card_klass, message)

    if params
      message = "Expected card params to be #{params}, but they were #{@application.cards.last.params}."
      assert @application.cards.last.params == params, message
    end
  end

  # Checks that focus was passed and (optionally) that any options 
  # were supplied.
  def assert_pass_focus(options = {})
    if @socket_string =~ /^<(?<type>\w+) \d+>\n(?<body>.+)?$/m
      message = Honcho::Message.new $~[:type], $~[:body]
    end

    unless message
      flunk "Expected focus to be passed, but no response was sent."
    end

    error = "Expected focus to be passed, but it was not"
    assert(message.type == :passfocus, error)

    if not options.empty?
      if message.body
        error = "Expected passfocus to be supplied with\n'#{options}' but it was supplied with\n'#{message.body}'."
        assert(message.body == options, error)
      else
        flunk "Expected passfocus to be passed '#{options}' but it was not passed any."
      end
    end
  end

  # Checks that the supplied button has the correct label
  def assert_button_label(button, expected_label)
    label = rendered[/<button position="#{button}">(.+?)<\/button>/, 1]
    error = "Expected #{button} button to have the label '#{expected_label}', but it had '#{label}'"
    assert(expected_label == label, error)
  end

  # Checks that the supplied button has the correct label
  def assert_text(expected_text)
    error = "Expected to find a <text> element containing '#{expected_text}', but none were found'"
    assert(rendered =~ /<text.*?>#{Regexp.escape(expected_text)}<\/text>/)
  end
end
