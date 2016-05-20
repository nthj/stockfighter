class Sloan::Game
  CLIENT = RestClient::Resource.
              prepend(Sloan::Client::Payload).
              new('https://www.stockfighter.io/gm')

  RateLimitExceeded = Class.new(StandardError)

  def initialize(level:, &block)
    trap("SIGINT") do
      puts 'RESTARTING LEVEL, will exit when complete'
      restart
      Sloan::Terminal[:debug] << 'EXIT'
      exit!
    end

    CLIENT['levels/%s' % level].post do |response, _, result|
      case response.code
      when 200
        ok, @account, @instance_id, @venue, @symbol = begin
          JSON.parse(response).values_at(
            *%w[ok account instanceId venues tickers]).flatten
        end
        ok or raise RateLimitExceeded
        Sloan::Terminal[:debug] << begin
          'Connected: %s,%s,%s' % [@account, @venue, @symbol]
        end
        Sloan::Client.with(@account, @venue, @symbol) do
          sleep until active?
          yield self
          sleep until won?
        end
      end
    end
  rescue RateLimitExceeded
    puts 'RATE LIMITED... retrying automatically in 60 seconds.'
    sleep 60
    retry
  end

  def active?
    JSON.parse(instance.get)['state'] == 'open'
  end

  def restart
    instance['restart'].post
  end

  def won?
    JSON.parse(instance.get)['done']
  end

protected

  def instance
    CLIENT['instances/%d' % @instance_id]
  end
end

