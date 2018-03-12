require 'net/http'
require 'json'

module OnlyofficeTestrailWrapper
  # Class to check bugzilla via http
  class BugzillaHelper
    attr_accessor :bugzilla_url

    def initialize(bugzilla_url: 'bugzilla.onlyoffice.com',
                   api_key: BugzillaHelper.read_token)
      @bugzilla_url = bugzilla_url
      @key = api_key
    end

    # Get status of bug
    # @param bug_id [String, Integer] id of bug
    # @return [String] status of bug
    def bug_status(bug_id)
      res = get_bug_result(bug_id, 80)
      res = get_bug_result(bug_id, 443) if response_redirect?(res)
      parsed_json = JSON.parse(res.body)
      parsed_json['bugs'].first['status']
    end

    # Get bug id from url
    # @param string [String] string for error
    # @return [Integer, Nil] result of bug id from url
    def bug_id_from_string(string)
      return nil unless string.include?(@bugzilla_url)
      string_without_bugzilla_url = string.gsub(@bugzilla_url, '')
      bug_id = string_without_bugzilla_url.gsub(/[^\d]/, '').to_i
      return nil if bug_id.zero?
      bug_id
    end

    # Read access token from file system
    # @return [String] token
    def self.read_token
      return ENV['BUGZILLA_API_KEY'] if ENV['BUGZILLA_API_KEY']
      File.read(Dir.home + '/.bugzilla/api_key').delete("\n")
    rescue Errno::ENOENT
      raise Errno::ENOENT, "No access token found in #{Dir.home}/.bugzilla/api_key" \
      "Please create files #{Dir.home}/.bugzilla/api_key"
    end

    private

    # @param id [Integer] id of bug
    # @return [String] url of bug on server with api key
    def bug_url(id)
      "/rest/bug/#{id}?api_key=#{@key}"
    end

    # @param bug_id [Integer] id of bug
    # @param port [Integer] port of server
    # @return [Net::HTTPResponse] result of request
    def get_bug_result(bug_id, port)
      Net::HTTP.start(@bugzilla_url, port, use_ssl: (port == 443)) do |http|
        http.get(bug_url(bug_id))
      end
    end

    # @param response [Net::HTTPResponse] to check
    # @return [Boolean] is response - redirect
    def response_redirect?(response)
      response.header['location']
    end
  end
end
