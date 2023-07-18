# frozen_string_literal: true

module OnlyofficeTestrailWrapper
  # Methods to perform operations on Runs
  module TestrailProjectRunMethods
    def test_run(name_or_id)
      case name_or_id.class.to_s
      when 'Integer'
        get_run_by_id name_or_id
      when 'String'
        init_run_by_name name_or_id
      else
        raise 'Wrong argument. Must be name [String] or id [Integer]'
      end
    end

    # Get all test runs of project
    # @return [Array<Hash>] array of test runs
    def get_runs(filters = {})
      get_url = "index.php?/api/v2/get_runs/#{@id}"
      filters.each { |key, value| get_url += "&#{key}=#{value}" }
      response = Testrail2.http_get(get_url)
      runs = response['runs']
      runs = runs.filter { |run| !run['plan_id'].nil? } if filters.key?(:plan_id)
      @runs_names = name_id_pairs(runs) if @runs_names.empty?
      runs
    end

    # Get all test runs of project as objects
    # @param [Hash] filters to apply
    # @return [Array<TestrailRun>] array of test runs
    def runs(filters = {})
      get_url = "index.php?/api/v2/get_runs/#{@id}"
      filters.each { |key, value| get_url += "&#{key}=#{value}" }
      runs = Testrail2.http_get(get_url)
      runs.map { |suite| TestrailRun.new.init_from_hash(suite) }
    end

    extend Gem::Deprecate
    deprecate :get_runs, 'runs', 2069, 1

    # Get Test Run by it's name
    # @param [String] name name of test run
    # @param [Int] plan_id id of plans for run search. Will search everything if nil
    # @return [TestRunTestRail] test run
    def get_run_by_name(name, plan_id: nil, milestone_id: nil)
      filter = {}
      filter[:plan_id] = plan_id if plan_id
      filter[:milestone_id] = milestone_id if milestone_id
      get_runs(filter) if @runs_names.empty?
      @runs_names[StringHelper.warnstrip!(name)].nil? ? nil : get_run_by_id(@runs_names[name])
    end

    def get_run_by_id(id)
      run = TestrailRun.new.init_from_hash(Testrail2.http_get("index.php?/api/v2/get_run/#{id}"))
      OnlyofficeLoggerHelper.log("Initialized run: #{run.name}")
      run.instance_variable_set(:@project, self)
      run
    end

    def init_run_by_name(name, suite_id = nil, milestone_id: nil, case_ids: nil)
      found_run = get_run_by_name(name, milestone_id: milestone_id)
      suite_id = get_suite_by_name(name).id if suite_id.nil?
      found_run.nil? ? create_new_run(name, suite_id, milestone_id: milestone_id, case_ids: case_ids) : found_run
    end

    def create_new_run(name, suite_id = nil, milestone_id: nil, case_ids: nil)
      data_hash = { name: StringHelper.warnstrip!(name),
                    description: '',
                    suite_id: suite_id }
      data_hash[:include_all] = case_ids.nil?
      data_hash[:milestone_id] = milestone_id if milestone_id
      data_hash[:suite_id] = suite_id if suite_id
      data_hash[:case_ids] = case_ids if case_ids
      new_run = TestrailRun.new.init_from_hash(Testrail2.http_post("index.php?/api/v2/add_run/#{@id}", data_hash))
      raise 'Error white run creating' unless new_run.id

      OnlyofficeLoggerHelper.log "Created new run: #{new_run.name}"
      new_run.instance_variable_set(:@project, self)
      @runs_names[new_run.name] = new_run.id
      new_run
    end

    # Get list of runs which older than several days
    # @param [Integer] days_old should pass to get this run
    # @param [Boolean] not_closed - return only not_closed runs
    # @return [Array<TestrailRun>] list of runs
    def runs_older_than_days(days_old, not_closed: true)
      closed_flag_digit = not_closed ? 0 : 1
      OnlyofficeLoggerHelper.log("Getting runs for #{@name}, days old: #{days_old}")
      unix_timestamp = Date.today.prev_day(days_old).to_time.to_i
      get_runs(created_before: unix_timestamp, is_completed: closed_flag_digit).map do |r|
        TestrailRun.new(r['name'],
                        r['description'],
                        r['suite_id'],
                        r['id'],
                        is_completed: r['is_completed'])
      end
    end
  end
end
