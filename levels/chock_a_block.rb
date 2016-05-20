require './lib/sloan'

Sloan::Game.new(level: :chock_a_block) do |game|
  @book = Sloan::Book.new
  @book.debug!
  @book.stream!
  @book.terminals_on!

  @book.on(:quote) do |quote|
    case @book
    when Sloan::Book::BLANK
      next unless quote.last
      Sloan::Order.buy(price: quote.last - 200, qty: 10_000).
        synchronize(:first) do |order|
          order.once(:first) do
            3.times { @book.orders << order.make }
          end
        end

      @book.buys.cancel!
    when Sloan::Book::CANCELED
      min_fill_price = @book.buys.collect(&:fills).flatten.
                             map { |f| f['price'] }.min.to_f

      if quote.ask < min_fill_price    # buy at low price
        Sloan::Order.buy(price: quote.ask, qty: 10_000).synchronize(:scoop) do |o|
          o.once(:scoop) { @book.orders << o.make }
        end
      end
    end
  end

  Thread.new { sleep 10; @book.buys.cancel! } # 2 days

  @book.on(:execution) do |order|
    # Cheat on synchronizing, it works here
    order.once(:crash) do # Crash the market!
      @book.buys.cancel!
    end
  end
end

