require './stockable'

class Order < OpenStruct
  extend Stockable
  include Synchronizable

  class << self
    def ask(price, qty, type = :limit); make(price, qty, :ask, type); end

    def buy(price, qty, type = :limit); make(price, qty, :buy, type); end

    def make(price, qty, direction, type = :limit)
      self.new JSON.parse post({ direction: direction,
                                 orderType: type,
                                     price: price,
                                       qty: qty             })
    end
  end

  def ask?
    direction == 'ask'
  end

  def buy?
    direction == 'buy'
  end

  def cancel
    @cancelled ||= true.tap do
      puts '=> Canceling #%d' % id
      self.class.client[id].delete(self.class.payload)
      puts '=> Canceled: #%d' % id
    end
  end

  def positioning
    buy? ? totalFulfilled : -totalFulfilled
  end
end

