class Terminal < Logger
  class << self
    def [](name) # woo singletons
      @windows ||= Hash.new { |h,k|  h[k] = self.new(name) }
      @windows[name]
    end
    protected :new
  end

  def initialize(name)
    super('%s.log' % name, File::CREAT|File::TRUNC)
  end
end

