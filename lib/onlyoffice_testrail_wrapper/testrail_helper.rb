# frozen_string_literal: true

require_relative 'testrail_helper/testrail_helper_rspec_metadata'
require_relative 'testrail_helper/example_failed_got_expected_exception'
require_relative 'testrail_helper/example_lpv_exception'
require_relative 'testrail_helper/example_service_unavailable_exception'
require_relative 'testrail'
require_relative 'helpers/ruby_helper'
require_relative 'helpers/system_helper'

module OnlyofficeTestrailWrapper
  # Class with help methods with testrail
  class TestrailHelper
    include RubyHelper
    include TestrailHelperRspecMetadata
    attr_reader :project, :plan, :suite, :run
    attr_accessor :add_all_suites, :suites_to_add, :case_ids, :in_debug, :version, :suite_filter

    def initialize(project_name, run_name = nil, milestone_name = nil, suite_name = nil)
      @in_debug = debug?
      @in_debug = false
      if @in_debug
        OnlyofficeLoggerHelper.log 'Do not initialize Testrail, because spec run in debug'
        @run = TestrailRun.new
        return
      end

      OnlyofficeLoggerHelper.log 'Begin initializing Testrail...'
      @project = Testrail2.new.project project_name
      @milestone = @project&.milestone(milestone_name) if milestone_name
      @all_sections = {}

      @suite = @project.suite(suite_name) if suite_name
      @case_ids = nil
      yield(self) if block_given?
      @run = @project.init_run_by_name(run_name, @suite.id, milestone_id: @milestone&.id, case_ids: case_ids) if @suite
      OnlyofficeLoggerHelper.log 'Initializing complete!'
    end

    def get_incomplete_tests
      @run.get_tests.filter_map { |test| test['title'] if test['status_id'] == 3 || test['status_id'] == 4 }
    end

    def add_result(example, comment: '', screenshot_path: nil)
      sections, test_name = parse_example(example)

      current_cache = @all_sections

      sections.each do |section_name|
        if current_cache[section_name]
          current_cache = current_cache[section_name]
        else
          section = @suite.section section_name, parent_section: current_cache[:section]&.id
          current_cache[section_name] = { section: section }
          current_cache = current_cache[section_name]
        end
      end
      section = current_cache[:section]

      result, comment, issue = get_result_from_example(example, comment)
      time = Time.now - example.execution_result.started_at
      custom_fields = { elapsed: format_elapsed_time(time),
                        defects: issue }

      current_case = section.case(test_name)
      update_case_if_needed(example, current_case)
      result = current_case.add_result @run.id, result, comment, custom_fields
      result.add_attachment(screenshot_path) if screenshot_path
      @last_case = example.full_description
    end

    private

    # divide example to [sections] and test
    def parse_example(example)
      test_name = example.metadata[:description]
      subsections = example.example_group.parent_groups.map(&:description).reverse
      [subsections, test_name]
    end

    # return id of current autotest relative of id in type case in testrail
    def example_type(example)
      return 11 if example.metadata[:smoke]

      3 # default type
    end

    def example_refs(example)
      example.metadata[:refs]
    end

    def example_location(example)
      example.metadata[:location]
    end

    def update_case_if_needed(example, current_case)
      type_id = example_type(example)
      refs = example_refs(example)
      location = example_location(example)
      cases_is_same = (current_case.type_id == type_id) && (current_case.refs == refs) && (current_case.custom_location == location)
      params = { type_id: type_id, refs: refs, location: location }
      current_case.update(params) unless cases_is_same
    end

    def init_run_in_plan(run_name)
      @plan.entries.each { |entry| @run = entry.runs.first if entry.name == run_name }
      @run = @plan.add_entry(run_name, @suite.id).runs.first if @run.nil?
      OnlyofficeLoggerHelper.log("Initialized run: #{@run.name}")
    end

    def all_suites_names
      @suites ? (return @suites) : @suites = []
      @project.get_suites
      @project.suites_names.each_key { |key| @suites << key }
      @suites.sort!
    end

    def suites_to_add_hash(suites_names)
      suites_names.map { |suite| all_suites_names.include?(suite) ? { 'suite_id' => @project.suites_names[suite] } : { 'suite_id' => @project.create_new_suite(suite).id } }
    end

    def get_result_from_example(example, comment)
      exception = example.exception
      issue = [*example.metadata[:defects]].join(', ')
      issue += [*example.metadata[:defect]].join(', ') # чтоб работало и с defect, и с defects: ['issue']
      if example.pending
        comment += example.execution_result.pending_message
        result = :pending
        if example.exception.to_s == 'Expected example to fail since it is pending, but it passed.'
          result = :failed
          comment = "Test passed! #{comment}"
        end
        example.add_custom_exception(comment) if result == :failed
      elsif exception.to_s.include?('got:') || exception.to_s.include?('expected:')
        testrail_exception = ExampleFailedGotExpectedException.new(example)
        result = testrail_exception.result
        comment += testrail_exception.comment
      elsif exception.to_s.include?('to return') || exception.to_s.include?('expected')
        result = :failed
        comment += "\n#{exception.to_s.gsub('to return ', "to return:\n").gsub(', got ', "\ngot:\n")}"
      elsif exception.nil?
        result = if @last_case == example.full_description
                   :passed_2
                 else
                   :passed
                 end
        comment += "\nOk"
      else
        result = :aborted
        comment += "\n#{exception}"
      end
      [result, comment, issue]
    end

    def format_elapsed_time(seconds)
      seconds = seconds.ceil
      minutes = seconds / 60
      seconds %= 60

      if minutes.zero?
        "#{seconds}s"
      else
        "#{minutes}m #{seconds}s"
      end
    end
  end
end
