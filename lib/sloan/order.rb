class Sloan::Order < OpenStruct
  class Collection < Array
    def method_missing(name, *args)
      each(&name)
    end
  end

  class << self
    %w[ask buy].each do |direction|
      define_method(direction) { |attrs|
        self.new(attrs.merge(direction: direction) ) }
    end
  end

  include Sloan::HashableStruct, Sloan::Synchronizable

  def make
    attrs = slice(:direction, :price, :qty).
            merge(  account: Sloan::Client.account,
                  orderType: type || :limit)

    Sloan::Terminal[:debug] << 'MAKE ORDER :: %s' % attrs.inspect
    Sloan::Client.stock['orders'].post(attrs) do |response, req|
      Sloan::Terminal[:debug] << req.inspect
      Sloan::Terminal[:debug] << response.inspect
      self.id = JSON.parse(response)['id']
    end

    self
  end

  def ask?;   direction.intern == :ask;   end
  def buy?;   direction.intern == :buy;   end

  def cancel!
    return unless open?
    Thread.new do
      synchronize([id, :cancel].join) do
        return unless open?
        begin
          Sloan::Terminal[:orders] << 'CANCEL   #%d' % id
          Client.orders[id].delete
          self.open = false
          Sloan::Terminal[:orders] << 'CANCELED #%d' % id
        rescue $!
          Sloan::Terminal[:orders] << 'CANCEL   #%d  FAILED' % id
          Sloan::Terminal[:debug]  << 'CANCEL FAILED'
          Sloan::Terminal[:debug]  << $!.message
        end
      end
    end
  end

  def open?
    self['open']
  end
end

