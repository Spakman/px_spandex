# Copyright (C) 2009 Mark Somerville <mark@scottishclimbs.com>
# Released under the General Public License (GPL) version 3.
# See COPYING

require "socket"
require "honcho/message"
require_relative "cache"

module Spandex
  class Application
    attr_reader :socket
    def initialize
      @socket = UNIXSocket.open "/tmp/#{File.basename($0)}.socket"
      @cards = []
      @cards_cache = Cache.new
      @has_focus = false
      load_card entry_point
    end

    # Can this application run in the background? In other words, when focus is
    # passed should the application remain active?
    def can_run_in_background?
      false
    end

    def self.can_run_in_background
      define_method "can_run_in_background?" do
        true
      end
    end

    def self.entry_point(klass)
      define_method :entry_point do
        klass
      end
    end

    # Loads a card. The cards are cached based on the contents of the card
    # stack. Spandex has been designed with tree-like application structures in
    # mind (like the menu system in Messier), but some cards can be accessed
    # via different branches (for example, one can arrive at the ArtistsCard in
    # Messier from the MenuCard or from the MenuCard via the GenresCard - in
    # this case there are two instances of the ArtistsCard in the cache).
    def load_card(klass, params = nil)
      stop_rendering if @cards.size > 0
      card = new_or_cached_instance_of(klass)
      card.responded = false
      card.params = params
      @cards << card
      @cards.last.call_show_chain
      card
    end

    def back_until(klass, params = nil)
      stop_rendering
      begin
        if @cards.pop.nil?
          raise "Cannot find an instance of #{klass} on the application stack."
        end
      end until @cards.last.instance_of? klass
      @cards.last.call_show_chain
    end

    # Fetches an instance of klass from the cache or instatiates it and adds it
    # to the cache.
    def new_or_cached_instance_of(klass)
      if klass.respond_to? :cache_index
        index = klass.cache_index
      else
        index = @cards.map { |c| c.class.hash.to_s }.join
        index += klass.hash.to_s
      end
      unless card = @cards_cache.get(index)
        card = klass.new(self)
      end
      @cards_cache.put index, card
    end

    # Go to the previous card. This removes the calling card from the stack. If
    # the calling card is the last card on the stack respond with a passfocus.
    def previous_card
      stop_rendering
      card = @cards.pop
      if @cards.last
        @cards.last.call_show_chain
      elsif can_run_in_background?
        # send a passfocus and put the card back on the stack so that something
        # is there when we return to the application!
        respond_pass_focus
        card.responded = true
        @cards << card
      else
        @socket << Honcho::Message.new(:closing)
        @socket.close
        exit
      end
      @cards.last
    end

    # Sends a render request to Honcho. Can take markup or a block argument to
    # render.
    #
    # Will only send a request when the application has focus and when render
    # was called by the active card.
    def render(card, markup = nil, &block)
      unless markup or block_given?
        raise "Trying to render without passing either markup or a block"
      end
      if @has_focus and card == @cards.last
        begin
          if block_given?
            markup = block.call
          end
          if markup.kind_of? String
            @socket << Honcho::Message.new(:render, markup)
          end
        rescue Errno::EPIPE
        end
      end
    end

    def stop_rendering
      @fib = nil
    end

    # Creates a new Fiber which calls and renders the passed block every few
    # (specified) seconds.
    #
    # TODO: compute the average time taken to call the block and adjust seconds
    # to compensate.
    def render_every(card, seconds, &block)
      if @has_focus
        @fib = Fiber.new do
          loop do
            if not @cards.last.responded
              Fiber.yield
              @cards.last.responded = true
            elsif IO.select([ @socket ], nil, nil, seconds)
              Fiber.yield
            end
            render @cards.last, &block
          end
        end
        @fib.resume
      end
    end

    # Send a keepfocus response to Honcho.
    def respond_keep_focus
      @socket << Honcho::Message.new(:keepfocus)
    end

    # Send a passfocus response to Honcho.
    def respond_pass_focus(options = nil)
      @socket << Honcho::Message.new(:passfocus, options)
      @has_focus = false
    end

    def run
      loop do
        begin
          if @fib and IO.select([ @socket ], nil, nil, 0).nil?
            @fib.resume
          end
          header = @socket.gets
        rescue Errno::ECONNRESET, Errno::EBADF, IOError
          break
        end
        if header =~ /^<(?<type>\w+) (?<length>\d+)>\n$/
          body = @socket.read $~[:length].to_i
          message = Honcho::Message.new $~[:type], body
          if message.type == :havefocus
            @has_focus = true
          end
          @cards.last.receive_message message
        end
      end
      @socket.close unless @socket.closed?
    end
  end
end
