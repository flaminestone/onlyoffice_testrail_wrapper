require 'spec_helper'

describe OnlyofficeTestrailWrapper::BugzillaHelper do
  let(:bugzilla) { OnlyofficeTestrailWrapper::BugzillaHelper.new }

  it 'check status of bug' do
    expect(bugzilla.bug_status(10)).to eq('CLOSED')
  end

  it 'bug_id_from_string correct url' do
    expect(bugzilla.bug_id_from_string("http://#{bugzilla.bugzilla_url}/show_bug.cgi?id=32296")).to eq(32_296)
  end

  it 'bug_id_from_string without digits' do
    expect(bugzilla.bug_id_from_string('test')).to be_nil
  end

  it 'bug_id_from_string with digits but another url' do
    expect(bugzilla.bug_id_from_string('http://bugzserver/show_bug.cgi?id=31427')).to be_nil
  end
end
