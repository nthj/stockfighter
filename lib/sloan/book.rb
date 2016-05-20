class Sloan::Book
  BLANK     = Class.new { def self.===(b); b.orders.length == 0; end; }
  CANCELED  = Class.new { def self.===(b); b.orders.none?(&:open?); end; }
  LONG      = Class.new { def self.===(b); b.position >  300; end; }
  SHORT     = Class.new { def self.===(b); b.position < -300; end; }

  include Sloan::Eventable

  def initialize
    @orders = Sloan::Order::Collection.new
    @ticker = []
  end
  attr_reader :orders, :ticker

  def asks; Sloan::Order::Collection.new(orders.select(&:ask?)); end
  def buys; Sloan::Order::Collection.new(orders.select(&:buy?)); end

  # Switches
  def debug!
    on(:debug) { |*payload| Sloan::Terminal[:debug] << payload.join(' :: ') }
  end

  def stats
    Sloan::Stats.new(self)
  end

  def stream!
    Stream.new(self)
  end

  def terminals_on!
    on(:execution) { Sloan::Terminal[:stats] << stats }
    on(:quote) do |quote|
      # Sloan::Terminal[:debug] << quote
      Sloan::Terminal[:ticker] << [quote.bid, quote.ask, quote.last].
        map { |w| w.to_s.rjust(10) }.join(' | ')
    end
  end
end

