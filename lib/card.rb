# Copyright (C) 2009 Mark Somerville <mark@scottishclimbs.com>
# Released under the General Public License (GPL) version 3.
# See COPYING

require "honcho/message"

module Spandex
  class Card
    attr_accessor :responded
    attr_reader :params

    # Creates a new Card.
    def initialize(application)
      @application = application
      @responded = false
      after_initialize
      @params = {}
    end

    def top_left; respond_keep_focus; end
    def top_right; respond_keep_focus; end
    def bottom_left; respond_keep_focus; end
    def bottom_right; respond_keep_focus; end
    def jog_wheel_button; respond_keep_focus; end
    def jog_wheel_left; respond_keep_focus; end
    def jog_wheel_right; respond_keep_focus; end

    def after_initialize; end
    def after_load; end
    def before_show; end
    def after_show; end

    def call_show_chain
      before_show
      show
      after_show
    end

    def params=(params)
      if params.nil?
        @params = {}
      else
        @params = params
      end
      after_load
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

    # Is used by Card.top_left and friends to define methods like Card#top_left
    # which are called when the Card receives input events.
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
    # TODO: check and warn when passing :card and :method that only one is
    #       allowed?
    # TODO: when :card is a Proc, it cannot take any arguments. Is this the
    #       desired behaviour?
    def self.setup_button_handler(button, options)
      if options == :back
        define_method button do
          @application.previous_card
          respond_keep_focus
        end
      elsif options[:card]
        define_method button do 
          card = call_proc_in_instance options[:card]
          unless card.kind_of? Class
            card = eval(card.to_s.capitalize.gsub(/_(\w)/) { |m| m[1].upcase })
          end
          params = call_proc_in_instance options[:params]

          @application.load_card card, params
          respond_keep_focus
        end
      elsif options[:method]
        define_method button do 

          params = call_proc_in_instance options[:params]

          if options[:method].respond_to? :call
            call_proc_in_instance options[:method], params
          else
            meth = method options[:method]
            if meth.arity == 0
              send options[:method]
            else
              send options[:method], params
            end
          end
          respond_keep_focus
        end
      end
    end

    # Convenience method.
    def load_card(klass, params = nil)
      card = @application.load_card klass, params
      respond_keep_focus
      card
    end

    # Returns the result of calling proc_or_not in the context of the instance. 
    # If option is not a Proc, it is simply returned.
    def call_proc_in_instance(proc_or_not, proc_params = nil)
      if proc_or_not.respond_to? :call
        if proc_or_not.arity == 0
          instance_exec &proc_or_not
        else
          instance_exec proc_params, &proc_or_not
        end
      else
        proc_or_not
      end
    end

    def receive_message(message)
      @responded = false
      case message.type
      when :havefocus
        call_show_chain
        respond_keep_focus
      when :inputevent
        send message.body.chomp.to_sym
      end
    end

    def already_responded?
      @responded
    end

    def respond_pass_focus(options = nil)
      unless already_responded?
        @application.respond_pass_focus options
        @responded = true
      end
    end

    alias_method :pass_focus, :respond_pass_focus

    def respond_keep_focus
      unless already_responded?
        @application.respond_keep_focus
        @responded = true
      end
    end

    def render(markup)
      @application.render self, markup
    end

    def render_every(seconds, &block)
      @application.render_every self, seconds, &block
    end
  end

  class ListCard < Card
    jog_wheel_left method: -> { @list.select_previous; call_show_chain }
    jog_wheel_right method: -> { @list.select_next; call_show_chain }
    jog_wheel_button card: -> { @list.selected }
  end
end
