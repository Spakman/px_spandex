require "#{File.dirname(__FILE__)}/message"

class Card
  def initialize(socket, application)
    @socket = socket
    @application = application
  end

  def self.top_left(symbol)
    setup_button_handler __method__, symbol
  end

  def self.top_right(symbol)
    setup_button_handler __method__, symbol
  end

  def self.bottom_left(symbol)
    setup_button_handler __method__, symbol
  end

  def self.bottom_right(symbol)
    setup_button_handler __method__, symbol
  end

  def self.setup_button_handler(button, symbol)
    if symbol == :back
      define_method button do
        @application.previous_card
        respond_keep_focus
      end
    else
      define_method button do
        @application.load_card eval(symbol.to_s.capitalize.gsub(/_(\w)/) { |m| m[1].upcase })
        respond_keep_focus
      end
    end
  end

  def receive_message(message)
    case message.type
    when :havefocus
      show
      respond_keep_focus
    when :inputevent
      send message.body.chomp.to_sym
    end
  end

  def respond_keep_focus
    @socket << Honcho::Message.new(:keepfocus)
  end

  def render(markup)
    @socket << Honcho::Message.new(:render, markup)
  end
end
