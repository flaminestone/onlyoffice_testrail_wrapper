module OnlyofficeTestrailWrapper
  class StringHelper
    class << self
      def warnstrip!(string)
        warn 'Beginning or end of string has spaces! In: ' + string unless string == string.strip
        string.strip
      end

      def get_string_elements_from_array(array, parameter, full_equality = false)
        array.select { |element| full_equality ? element == parameter : element.include?(parameter) }
      end
    end
  end
end
