require "#{File.dirname(__FILE__)}/message"

class Card
  attr_accessor :params

  def initialize(socket, application)
    @socket = socket
    @application = application
  end

  # Defines what should happen when the top left button is pressed.
  #
  # Calls Card.setup_button_handler
  def self.top_left(options)
    setup_button_handler __method__, options
  end

  # Defines what should happen when the top right button is pressed.
  #
  # Calls Card.setup_button_handler
  def self.top_right(options)
    setup_button_handler __method__, options
  end

  # Defines what should happen when the bottom left button is pressed.
  #
  # Calls Card.setup_button_handler
  def self.bottom_left(options)
    setup_button_handler __method__, options
  end

  # Defines what should happen when the jog wheel is turned anti-clockwise.
  #
  # Calls Card.setup_button_handler
  def self.jog_wheel_left(options)
    setup_button_handler __method__, options
  end

  # Defines what should happen when the jog wheel is turned clockwise.
  #
  # Calls Card.setup_button_handler
  def self.jog_wheel_right(options)
    setup_button_handler __method__, options
  end

  # Defines what should happen when the jog wheel button is pressed.
  #
  # Calls Card.setup_button_handler
  def self.jog_wheel_button(options)
    setup_button_handler __method__, options
  end

  # Defines what should happen when the bottom right button is pressed.
  #
  # Calls Card.setup_button_handler
  def self.bottom_right(options)
    setup_button_handler __method__, options
  end

  # Is used by Card.top_left and friends to define methods like Card#top_left which are called when the Card receives input events.
  #
  # === Options
  #
  # [:back]
  #   A special case that takes no other options. Focus is given to the previous card.
  # [:card]
  #   A symbol, string representation (or a Proc that returns one) the class of the target Card. This is should be the underscored name of the class.
  # [:method]
  #   A symbol or string of a method name within the current Card that is to be called.
  # [:params]
  #   Any object that should be passed to the target Card or method as a parameter. Procs are evaluated when the method is called.
  #
  # Option examples:
  #   top_left :back
  #   top_right :card => :artist_list
  #   top_right card: -> { get_target_card_name }
  #   bottom_left :method => :remove_item
  #   bottom_right :card => :artist_list, params: -> { @current_thing }
  #   bottom_right :method => :remove_item, params: -> { @current_item }
  #
  # TODO: check and warn when passing :card and :method that only one is allowed?
  # TODO: when :card is a Proc, it cannot take any arguments. Is this the desired behaviour?
  def self.setup_button_handler(button, options)
    if options == :back
      define_method button do
        @application.previous_card
        respond_keep_focus
      end
    elsif options[:card]
      define_method button do 
        if options[:card].respond_to? :call
          card = instance_eval &options[:card]
        else
          card = options[:card]
        end

        if options[:params].respond_to? :call
          params = options[:params].call 
        else
          params = options[:params]
        end
        @application.load_card eval(card.to_s.capitalize.gsub(/_(\w)/) { |m| m[1].upcase }), params
        respond_keep_focus
      end
    elsif options[:method]
      define_method button do 
        if options[:params].respond_to? :call
          params = options[:params].call 
        else
          params = options[:params]
        end
        if options[:method].respond_to? :call
          if options[:method].arity == 0
            instance_eval &options[:method]
          else
            instance_exec params, &options[:method]
          end
        else
          send options[:method], params
        end
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