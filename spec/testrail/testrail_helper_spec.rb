require 'spec_helper'
describe OnlyofficeTestrailWrapper::TestrailHelper do
  let(:helper) { OnlyofficeTestrailWrapper::TestrailHelper.new('Test Project', 'Test Suite', 'Test Plan') }

  describe 'TestrailHelper#add_result_to_test_case' do
    it 'Add test result with exception' do
      helper.add_result_to_test_case(OnlyofficeTestrailWrapper::RspecExampleMock.new)
    end
  end
end
