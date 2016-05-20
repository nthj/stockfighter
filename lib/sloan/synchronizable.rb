module Sloan::Synchronizable
  def once(keys = [self.id, self.totalFilled], &block)
    (@@once ||= {})[Array(keys).join] ||= true.tap(&block)
  end

  def synchronize(key = self.id, &block)
    @@mutexes ||= Hash.new { |h,k| h[k] = Mutex.new }

    @@mutexes[key].synchronize do
      yield *[self].take(block.arity)
    end
  end

end

