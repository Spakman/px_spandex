# Copyright (C) 2009 Mark Somerville <mark@scottishclimbs.com>
# Released under the General Public License (GPL) version 3.
# See COPYING

require "socket"
require "honcho/message"
require_relative "cache"

module Spandex
  class Application
    attr_reader :have_focus

    def initialize
      @socket = UNIXSocket.open "/tmp/#{File.basename($0)}.socket"
      @cards = []
      @cards_cache = Cache.new
      @have_focus = false
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
      @cards.last.stop_rendering if @cards.size > 0
      index = @cards.map { |c| c.class.hash.to_s }.join
      index += klass.hash.to_s
      unless card = @cards_cache.get(index)
        card = klass.new(self)
      end
      card.params = params
      @cards_cache.put index, card
      @cards << card
      @cards.last.show
      card
    end

    def previous_card
      card = @cards.pop
      card.stop_rendering
      if @cards.last
        @cards.last.show
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

    def unfocus
      @have_focus = false
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
      if have_focus and card == @cards.last
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

    def respond_keep_focus
      @socket << Honcho::Message.new(:keepfocus)
    end

    def respond_pass_focus(options = nil)
      @socket << Honcho::Message.new(:passfocus, options)
      unfocus
    end

    def run
      loop do
        begin
          header = @socket.gets
        rescue Errno::ECONNRESET, Errno::EBADF, IOError
          break
        end
        if header =~ /^<(?<type>\w+) (?<length>\d+)>\n$/
          body = @socket.read $~[:length].to_i
          message = Honcho::Message.new $~[:type], body
          if message.type == :havefocus
            @have_focus = true
          end
          @cards.last.receive_message message
        end
      end
      @socket.close unless @socket.closed?
    end
  end
end
