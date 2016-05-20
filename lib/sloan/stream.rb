# Consolidates websoc1kets with polling, since websockets are flaky
class Stream
  def initialize(book)
    @book       = book

    poll!   # will poll, and
    stream! # also stream, but only publish each once
  end

  Disconnect = Class.new(StandardError)
  def stream!
    quote_receipt_time = order_receipt_time = Time.now

    sockets do |socket|
      socket.on(:open)  { @book.publish(:debug, 'socket:open') }
      socket.on(:close) { raise Disconnect }
      socket.on(:message) do |event|
        # @book.publish(:debug, 'socket:event', Time.now, event.data)
        JSON.parse(event.data).tap do |data|
          quote_receipt_time = Time.now and try_quote(data)     if data['quote']
          order_receipt_time = Time.now and try_execution(data) if data['order']
        end
      end
    end

    @book.on(:quote) do
      raise Disconnect if (Time.now - quote_receipt_time).to_i > 10
    end
    @book.on(:execution) do
      raise Disconnect if (Time.now - order_receipt_time).to_i > 10
    end
  rescue Disconnect
    retry
  end

  def poll!
    Thread.new do # Quotes
      loop do
        # TODO
        try_quote book.client['quote'].get
        sleep 1
      end
    end

    Thread.new do # Fills
      loop do
        sleep 5
        begin
          Sloan::Client.orders.get do |response|
            case response.code
            when 200
              JSON.parse(response)['orders'].each do |order|
                try_execution(order)
              end
            when 500
              @book.publish(:debug, 'FAILED: ', response.body)
            end
          end
        rescue
          @book.publish(:debug, 'GET orderbook failed: ', $!.message,
                        *$!.backtrace[0..5])
        end
      end
    end
  end

  def try_execution(message)
    Sloan::Order.new(message['order'] || message).synchronize do |order|
      s     = ->(o) { o.id == order.id }
      order = [order, @book.orders.find(&s)].compact.sort_by(&:filledAt).last
      @book.orders.delete_if(&s)
      @book.orders << order
      order.once { @book.publish(:execution, order) }
    end
  end

  def try_quote(message)
    @book.ticker << Sloan::Quote.new(message['quote'])
    @book.publish(:quote, Sloan::Quote.new(message['quote']))
  end

protected

  def sockets &block
    Thread.new do
      EM.run do
        %w[executions tickertape].each do |type|
          @book.publish(:debug, 'socket:connecting', type)
          yield Faye::WebSocket::Client.new(
            SOCKET_URL % [Sloan::Client.account, Sloan::Client.venue, type])
        end
      end
    end
  end

  SOCKET_URL = 'wss://api.stockfighter.io/ob/api/ws/%s/venues/%s/%s'
end

