require 'rspec'
require_relative '../../testing_shared'

describe Testrail2 do
  describe 'available?' do
    it 'check availability of correct connection' do
      expect(Testrail2.new).to be_available
    end

    it 'check non-availability of correct connection' do
      Testrail2.testrail_url = 'www.ya.ru'
      expect(Testrail2.new).not_to be_available
    end
  end
end
