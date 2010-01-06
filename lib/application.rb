# Copyright (C) 2009 Mark Somerville <mark@scottishclimbs.com>
# Released under the General Public License (GPL) version 3.
# See COPYING

require "socket"
require "honcho/message"

module Spandex
  class Application
    def initialize
      @socket = UNIXSocket.open "/tmp/#{File.basename($0)}.socket"
      @cards = []
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

    def load_card(klass, params = nil)
      @cards << klass.new(@socket, self)
      @cards.last.params = params
      @cards.last.show
    end

    def previous_card
      card = @cards.pop
      if @cards.last
        @cards.last.show
      elsif can_run_in_background?
        # send a passfocus and put the card back on the stack so that something
        # is there when we return to the application!
        @socket << Honcho::Message.new(:passfocus)
        card.responded = true
        @cards << card
      else
        @socket << Honcho::Message.new(:closing)
        @socket.close
        exit
      end
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
          @cards.last.receive_message message
        end
      end
      @socket.close unless @socket.closed?
    end
  end
end
