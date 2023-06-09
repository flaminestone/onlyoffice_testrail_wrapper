# frozen_string_literal: true

require 'onlyoffice_bugzilla_helper'
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
    attr_accessor :add_all_suites, :suites_to_add, :in_debug, :version, :suite_filter

    def initialize(project_name, suite_name = nil, plan_name = nil, run_name = nil, milestone_name = nil)
      # @in_debug = debug?
      @in_debug = false
      if @in_debug
        OnlyofficeLoggerHelper.log 'Do not initialize Testrail, because spec run in debug'
        @run = TestrailRun.new
        return
      end

      OnlyofficeLoggerHelper.log 'Begin initializing Testrail...'
      @suites_to_add = []
      @all_sections = {}
      @add_all_suites = true
      yield(self) if block_given?
      @project = Testrail2.new.project project_name
      @milestone = @project.milestone(milestone_name) if milestone_name
      if plan_name
        @plan = @project.get_plan_by_name(plan_name.to_s)
        @suites_to_add = all_suites_names.grep(suite_filter) if suite_filter
        suites = suites_to_add_hash(@add_all_suites ? all_suites_names : @suites_to_add)
        @plan ||= @project.create_new_plan(plan_name, suites, '', @milestone&.id)
      end
      return if suite_name.nil?

      @suite = @project.suite suite_name.to_s
      if @plan
        init_run_in_plan(suite_name.to_s)
      else
        @run = @project.init_run_by_name(run_name ? run_name.to_s : suite_name.to_s, @suite.id)
      end
      raise "Plan '#{@plan.name}' is completed! Cannot add results. See #{@plan.url}" if !@plan.nil? && @plan.is_completed

      OnlyofficeLoggerHelper.log 'Initializing complete!'
    end

    def add_cases_to_suite(cases, section_name = 'All Test Cases')
      if @in_debug
        OnlyofficeLoggerHelper.log 'Do not add test result, because spec run in debug '
        return
      end
      OnlyofficeLoggerHelper.log "Begin scanning #{@suite.name} suite for new cases" unless cases.is_a?(Array)
      section = @suite.section section_name.to_s
      existing_cases = section.get_cases.map { |test_case| test_case['title'] }
      cases.each { |case_name| section.create_new_case case_name.to_s unless existing_cases.include?(case_name) }
      OnlyofficeLoggerHelper.log 'Suite scanning complete!'
      @suite = @project.get_suite_by_id @suite.id
    end

    def add_result_to_test_case(example, comment = '', section_hierarchies: ['All Test Cases'], suite_name: nil)
      section_hierarchies = [*section_hierarchies]
      if @in_debug
        OnlyofficeLoggerHelper.log 'Do not add test result, because spec run in debug '
        return
      end
      raise 'Do not know where to add result' unless suite_name || @run

      exception = example.exception
      custom_fields = init_custom_fields(example)
      if example.pending
        result, comment, bug_id = parse_pending_comment(example.execution_result.pending_message)
        if example.exception.to_s == 'Expected example to fail since it is pending, but it passed.'
          result = :failed
          comment = "Test passed! #{comment}"
        end
        custom_fields[:defects] = bug_id.to_s
        example.add_custom_exception(comment) if result == :failed
        result = :lpv if comment.downcase.include?('limited program version')
      elsif exception.to_s.include?('got:') || exception.to_s.include?('expected:')
        testrail_exception = ExampleFailedGotExpectedException.new(example)
        result = testrail_exception.result
        comment += testrail_exception.comment
      elsif exception.to_s.include?('to return') || exception.to_s.include?('expected')
        result = :failed
        comment += "\n#{exception.to_s.gsub('to return ', "to return:\n").gsub(', got ', "\ngot:\n")}"
      elsif exception.to_s.include?('Service Unavailable')
        testrail_exception = ExampleServiceUnavailableException.new(example)
        result = testrail_exception.result
        comment += testrail_exception.comment
      elsif exception.to_s.include?('Limited program version')
        testrail_exception = ExampleLPVException.new(exception)
        result = testrail_exception.result
        comment += testrail_exception.comment
      elsif exception.nil?
        result = if @last_case == example.description
                   :passed_2
                 elsif custom_fields.key?(:custom_js_error)
                   :js_error
                 else
                   :passed
                 end
        comment += "\nOk"
      else
        result = :aborted
        comment += "\n#{exception}"
        custom_fields[:custom_autotest_error_line] = exception.backtrace.join("\n") unless exception.backtrace.nil?
      end
      @last_case = example.description
      @suite = @project.suite(suite_name) unless @suite&.name == suite_name
      current_cache = @all_sections

      section_hierarchies.each do |section_name|
        if current_cache[section_name]
          current_cache = current_cache[section_name]
        else
          section = @suite.section section_name, parent_section: current_cache[:section]&.id
          current_cache[section_name] = {section: section}
          current_cache = current_cache[section_name]
        end
      end
      section = current_cache[:section]
      init_run_in_plan(suite_name.to_s)
      section.case(example.description).add_result @run.id, result, comment, custom_fields
    end

    def get_incomplete_tests
      @run.get_tests.filter_map { |test| test['title'] if test['status_id'] == 3 || test['status_id'] == 4 }
    end

    private

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
  end
end
