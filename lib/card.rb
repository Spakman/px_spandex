require "#{File.dirname(__FILE__)}/message"

class Card
  attr_accessor :params

  def initialize(socket, application)
    @socket = socket
    @application = application
  end

  def self.top_left(options)
    setup_button_handler __method__, options
  end

  def self.top_right(options)
    setup_button_handler __method__, options
  end

  def self.bottom_left(options)
    setup_button_handler __method__, options
  end

  def self.bottom_right(options)
    setup_button_handler __method__, options
  end

  def self.setup_button_handler(button, options)
    if options == :back
      define_method button do
        @application.previous_card
        respond_keep_focus
      end
    elsif options[:card]
      define_method button do 
        if options[:params].respond_to? :call
          params = options[:params].call 
        else
          params = options[:params]
        end
        @application.load_card eval(options[:card].to_s.capitalize.gsub(/_(\w)/) { |m| m[1].upcase }), params
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
