class Sloan::Terminal < Logger
  class << self
    def [](name) # woo singletons
      @windows ||= Hash.new { |h,k|  h[k] = self.new(k) }
      @windows[name]
    end
    protected :new
  end

  def initialize(name)
    super('terminals/%s.log' % name, File::CREAT)
  end

  def <<(message)
    super "#{message}\n"
  end
end

