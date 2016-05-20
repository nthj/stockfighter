module Sloan::HashableStruct
  def to_h
    super.tap do |hash|
      hash.default_proc = proc do |h, k|
        case k
        when String then h[k.intern] if h.key?(k.intern)
        when Symbol then h[k.to_s]   if h.key?(k.to_s)
        end
      end
    end
  end

  def slice(*keys)
    to_h.tap do |hash|
      keys.each { |key| hash[key] = send(key) }
    end
  end

  def merge(other)
    to_h.merge(other)
  end
end

