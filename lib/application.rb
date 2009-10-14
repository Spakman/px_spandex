require "#{File.dirname(__FILE__)}/message"

class Application
  def initialize
    @socket = UNIXSocket.open "/tmp/messier.socket"
    @cards = []
    load_card entry_point
  end

  def self.entry_point(symbol)
    define_method :entry_point do
      eval symbol.to_s.capitalize.gsub(/_(\w)/) { |m| m[1].upcase }
    end
  end

  def load_card(klass, params = nil)
    @cards << klass.new(@socket, self)
    @cards.last.params = params
    @cards.last.show
  end

  def previous_card
    @cards.pop
    if @cards.last
      @cards.last.show
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
      if header =~ /^<(\w+) (\d+)>\n$/
        body = @socket.read $2.to_i
        message = Honcho::Message.new $1, body
        @cards.last.receive_message message
      end
    end
    @socket.close unless @socket.closed?
  end
end