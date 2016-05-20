class Sloan::Stats
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

