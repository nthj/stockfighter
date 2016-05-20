class Sloan::Stats
  def initialize(book)
    @book = book
  end

  def cash
    '$' + ( @book.orders.select(&:fills).collect { |order|
      order.fills.collect { |fill| order.buy? ? -price : price }
    }.flatten.inject(&:+) / 100.0 ).to_s
  end

  # net asset value
  # Net asset value (NAV) is the value of an entity's assets,
  # minus the value of its liabilities
  # https://en.wikipedia.org/wiki/Net_asset_value
  def nav
    number_of_stocks * @book.quotes.last.last + cash.to_f
  end

  def number_of_stocks
    @book.orders.select(&:buy?).collect(&:totalFilled).inject(&:+) -
    @book.orders.select(&:ask?).collect(&:totalFilled).inject(&:+)
  end

  def position
    @book.orders.inject { |position, order| position + order.positioning }
  end

  def to_s
    {     cash: cash,
           nav: nav,
      position: position }.map { |k,v| "#{k.rjust(20) }: #{v.ljust(7)}" }.join
  end
end

