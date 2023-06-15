# frozen_string_literal: true

module OnlyofficeTestrailWrapper
  # Module for working with rspec metadata
  module TestrailHelperRspecMetadata
    # @return [String] version of tested app
    def version
      return @version if @version
      return @plan.name if @plan&.name

      'Unknown'
    end

    # @return [String] example execution time in seconds
    def example_time_in_seconds(example)
      execution_time = (Time.now - example.metadata[:execution_result].started_at).to_i
      execution_time = 1 if execution_time.zero? # Testrail cannot receive 0 as elapsed time
      "#{execution_time}s"
    end

    # Fill default values for custom fields
    # @param [RSpec::Core::Example] example with metadata
    # @return [Hash] custom fields
    def init_custom_fields(example)
      custom_fields = {}
      # TODO: Fix dependencies from other project
      return custom_fields if defined?(AppManager).nil?

      custom_fields[:elapsed] = example_time_in_seconds(example)
      custom_fields[:version] = version
      custom_fields[:custom_host] = SystemHelper.hostname
      custom_fields[:custom_screenshot_link] = screenshot_link if example.exception
      custom_fields
    end

    # @return [String] link to screenshot
    # empty string if not supported
    def screenshot_link
      return AppManager.create_screenshots if AppManager.respond_to?(:create_screenshots)

      ''
    end
  end
end
