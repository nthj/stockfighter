module Eventable
protected
  def events; @events ||= Hash.new { |h,k| h[k] = [] }; end
public
  def on(event, &block)
    self.events[event] << block
  end

  def publish(event, *payload)
    events[event].each do |handler|
      handler.call *payload.take(handler.arity) # will not handle -1
    end
  end
end

