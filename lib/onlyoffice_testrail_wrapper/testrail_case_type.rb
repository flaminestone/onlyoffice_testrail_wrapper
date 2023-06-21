# frozen_string_literal: true

module OnlyofficeTestrailWrapper
  # @author Dmitriy.Rotatyy
  # Class for description of test case
  class TestrailCaseType < TestrailApiObject
    # @return [Integer] Id of case type
    attr_accessor :id
    # @return [String] title of case type
    attr_accessor :title
    # @return [Boolean] is_default type?
    attr_accessor :is_default

    # Default constructor
    # @param [String] title name of test case type name
    # @param [Integer] id Id of test case type
    # @param [Boolean] is_default is_default type?
    # @return [TestCaseTestrail] new test case
    def initialize(id = nil, title = nil, is_default = nil)
      super()
      @id = id
      @title = title
      @is_default = type_id
    end
  end
end
