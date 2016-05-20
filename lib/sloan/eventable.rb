module Sloan::Eventable
protected
  def events; @events ||= Hash.new { |h,k| h[k] = [] }; end
public
  def on(event, &block)
    self.events[event] << block
  end

  def publish(event, *payload)
    events[event].each do |handler|
      Thread.new do
        begin
          handler.call *handler.arity < 0 ? payload : payload.take(handler.arity)
        rescue
          Sloan::Terminal[:debug] << $!.message
          Sloan::Terminal[:debug] << $!.backtrace[0..5].join("\n")
        end
      end
    end
  end
end

