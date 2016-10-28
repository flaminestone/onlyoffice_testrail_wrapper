module OnlyofficeTestrailWrapper
  # Mock Rspec example exception
  class RspecExceptionMock
    attr_accessor :backtrace

    def initialize
      @backtrace = %w(TestBackTraceLine1 TestBackTraceLine2)
    end
  end

  # Mock Rspec example
  class RspecExampleMock
    attr_accessor :exception
    attr_accessor :backtrace
    attr_accessor :metadata
    attr_accessor :pending
    attr_accessor :description

    def initialize
      @exception = RspecExceptionMock.new
      @metadata = {}
      @pending = false
      @description = 'MockDescription'
    end
  end
end
