# frozen_string_literal: true

module OnlyofficeTestrailWrapper
  # Methods to perform operations on case type
  module TestrailProjectCaseTypeMethods
    # @param [String] name of case type
    # @return [TestrailCaseType]
    def case_type(name)
      case name.class.to_s
      when 'Fixnum', 'Integer'
        raise 'There is no way to get case type by'
      when 'String'
        get_case_type_by_name name
      else
        raise 'Wrong argument. Must be name [String] or id [Integer]'
      end
    end

    # Get case type data by it's name
    # @param [String] name of case type
    # @return [TestrailCaseType, nil] result or nil if not found
    def get_case_type_by_name(name)
      get_case_types if @case_types.empty?
      @case_types[StringHelper.warnstrip!(name.to_s)]
    end

    # Get list of all case types
    # @return [Array<TestrailCaseType>] list of all case types
    def get_case_types
      response = Testrail2.http_get('index.php?/api/v2/get_case_types')
      @case_types = name_id_pairs(response) if @case_types.empty?
      @case_types
    end
  end
end
