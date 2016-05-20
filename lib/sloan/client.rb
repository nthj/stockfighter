class Sloan::Client
  module Payload
    %w[get post delete].each do |method|
      define_method(method) do |*args, &block|
        if method == 'post'
          args << { } if args.empty?
          args[0] = args[0].to_json
        end # kludgey
        super(*args, payload, &block)
      end
    end
  protected
    def payload
      raise 'no $API_KEY' if ENV['API_KEY'].nil?
      { 'X-Starfighter-Authorization' => ENV['API_KEY'] }
    end
  end
end

class << Sloan::Client
  CLIENT = RestClient::Resource.
            prepend(Sloan::Client::Payload).
            new('https://api.stockfighter.io/ob/api/')

  def stock
    CLIENT['venues/%s/stocks/%s' % [@venue, @symbol]]
  end

  def orders
    CLIENT['venues/%s/accounts/%s/stocks/%s/orders' % [@venue, @account, @symbol]]
  end

  attr_reader :account, :venue, :symbol

  def with(account, venue, symbol, &block)
    @account, @venue, @symbol = account, venue, symbol
    yield
  ensure
    @account, @venue, @symbol = nil
  end
end

