class Book
  LONG  = Class.new { def ===(p); p >  300; end; }
  SHORT = Class.new { def ===(p); p < -300; end; }

  include Enumerable, Eventable

  def initialize
    @orders = []
  end

  def <<(order)
    # only add once
    # return nil if already here
  end

  def each(&block)
    @orders.each(&block)
  end

  def stream!
    @stream ||= Stream.new(self)
  end

  def stats
    Stats.new(self)
  end
  delegate :cash, :nav, :position, to: :stats

  class Stats
    def initialize(book)
      @book = book
    end

    def cash
      "$0.00"
    end

    def nav
      0
    end

    def position
      inject { |position, order| position + order.positioning }
    end

    def to_s
      map { |k,v| "#{k.rjust(20) }: #{v.ljust(7)}" }.join
    end
  end
end

