require 'faye/websocket'
require 'json'
require 'ostruct'
require 'rest-client'
require 'stockfighter'

Dir['./*.rb'].each { |file| require file }

Stockfighter::GM.new(key: ENV['API_KEY'], level: 'sell_side').tap do |master|
  master.restart; sleep until master.active?

  Order.with(*master.config.values_at(:account, :venue, :symbol)) do
    @book = Book.new
    @book.stream!

    # Cancel orders when too long or too short
    @book.on(:execution) do |order|
      case @book.position
      when Book::LONG   then @book.select(&:buy?).each(&:cancel)
      when Book::SHORT  then @book.select(&:ask?).each(&:cancel)
      end
    end

    # Buy or sell more based on trends
    @book.on(:quote) do |quote|
      case @book.position
      when Book::LONG   then Order.ask(10, 10)
      when Book::SHORT  then Order.buy(10, 10)
      end
    end

    # Update our terminals with high-level stats
    @book.on(:execution) do |order|
      Terminal[:stats] << @book.stats
    end

    @book.on(:quote) do |quote|
      Terminal[:ticker] << [
        [ quote.bid,  quote.bid - book.select(&:buy?).last.bid, 0 ],
        [ quote.ask,  quote.ask - book.select(&:ask?).last.ask, 0 ],
        [ quote.last, :current_spread, :our_spread ]
      ].map { |(q,l,o)| "#{q.rjust(7)} (#{l}) (#{o})" }.join ' | '
    end

    @book.on(:debug) { |*payload| Terminal[:debug] << payload.join(' :: ') }
  end
end

