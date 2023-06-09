# frozen_string_literal: true

require_relative 'testrail_project'
require_relative 'testrail_section'
require_relative 'testrail_run'

module OnlyofficeTestrailWrapper
  # @author Roman.Zagudaev
  # Class for description of test suites
  class TestrailSuite < TestrailApiObject
    # @return [Integer] Id of test suite
    attr_accessor :id
    # @return [String] Name of test suite
    attr_accessor :name
    # @return [String]  description of test suite
    attr_accessor :description
    # @return [true, false] id of project of test suite
    attr_accessor :project_id
    # @return [Array] sections in suite
    attr_accessor :sections_names
    # @return [String] url to current suite
    attr_reader :url

    # Default constructor
    # @param [Integer] id id of test suite, default = nil
    # @param [String] name name of test suite, default = nil
    # @param [String] description description of test suite, default = nil
    # @param [Integer] project_id id of project of test suite
    # @return [TestrailSuite] new Test suite
    def initialize(name = nil, description = nil, project_id = nil, id = nil)
      super()
      @id = id
      @name = name
      @description = description
      @project_id = project_id
    end

    # Start test run from test suite
    # @param [String] name name of started test run
    # @param [String] description description of test run
    # @return [TestRunTestRail] created test run
    def start_test_run(name, description = '')
      TestrailRun.new.init_from_hash(Testrail2.http_post("index.php?/api/v2/add_run/#{@project_id}",
                                                         name: StringHelper.warnstrip!(name.to_s),
                                                         description: description,
                                                         suite_id: @id))
    end

    def section(name_or_id = 'All Test Cases', parent_section: nil)
      case name_or_id.class.to_s
      when 'Fixnum'
        get_section_by_id name_or_id
      when 'String'
        init_section_by_name name_or_id, parent_section
      else
        raise 'Wrong argument. Must be name [String] or id [Integer]'
      end
    end

    # Create new section of test suite
    # @param [String] name of test section to create
    # @param [Integer] parent_section id of parent section, default = nil
    def create_new_section(name, parent_section = nil)
      parent_section = get_section_by_name(parent_section).id if parent_section.is_a?(String)
      new_section = TestrailSection.new.init_from_hash(Testrail2.http_post("index.php?/api/v2/add_section/#{@project_id}",
                                                                           name: StringHelper.warnstrip!(name.to_s),
                                                                           parent_id: parent_section,
                                                                           suite_id: @id))
      OnlyofficeLoggerHelper.log "Created new section: #{new_section.name}"
      @sections_names[new_section.name] = new_section.id
      new_section.instance_variable_set :@project_id, @project_id
      new_section.instance_variable_set :@suite, self
      new_section
    end

    # Get all sections in test suite
    # @return [Array, TestrailSuite] array with sections
    def get_sections
      response = Testrail2.http_get("index.php?/api/v2/get_sections/#{@project_id}&suite_id=#{@id}")
      sections = response['sections']
      @sections_names = name_id_pairs(sections) if @sections_names.nil?
      sections
    end

    def get_section_by_id(id)
      section = TestrailSection.new.init_from_hash(Testrail2.http_get("index.php?/api/v2/get_section/#{id}"))
      section.instance_variable_set :@project_id, @project_id
      section.instance_variable_set :@suite, self
      section
    end

    def get_section_by_name(name)
      get_sections if @sections_names.nil?
      @sections_names[StringHelper.warnstrip!(name.to_s)].nil? ? nil : get_section_by_id(@sections_names[name])
    end

    # Init section by it's name
    # @param [String] name name of section
    # @return [TestrailSection] Section with this name
    def init_section_by_name(name, parent_section = nil)
      found_section = get_section_by_name name
      found_section.nil? ? create_new_section(name, parent_section) : found_section
    end

    # Delete current test suite
    # @return [nil]
    def delete
      Testrail2.http_post "index.php?/api/v2/delete_suite/#{@id}", {}
      OnlyofficeLoggerHelper.log "Deleted suite: #{@name}"
      @project.suites_names.delete @name
      nil
    end

    def update(name, description = nil)
      @project.suites_names.delete @name
      @project.suites_names[StringHelper.warnstrip!(name.to_s)] = @id
      updated_suite = TestrailSuite.new.init_from_hash(Testrail2.http_post("index.php?/api/v2/update_suite/#{@id}",
                                                                           name: name,
                                                                           description: description))
      OnlyofficeLoggerHelper.log "Updated suite: #{updated_suite.name}"
      updated_suite
    end
  end
end
