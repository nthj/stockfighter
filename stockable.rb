module Stockable
  CLIENT = RestClient::Resource.new('https://api.stockfighter.io/ob/api/')

  def with account, venue, stock, &block
    @account, @venue, @stock = account, venue, stock
    yield
  ensure
    @account, @venue, @stock = nil, nil, nil
  end
  attr_reader :account, :venue

  def client
    CLIENT['venues/%s/stocks/%s' % [@venue, @stock]]
  end

  def post data
    data.merge! account: @account
    client['orders'].post(data.to_json, payload).tap do |response|
      book.publish(:debug, data, payload, response)
    end
  end

  def payload
    { 'X-Starfighter-Authorization': ENV['API_KEY'] }
  end
end

