require 'spec_helper'

describe StringHelper do
  warnstrip_string = 'test end space'

  it 'StringHelper.warnstrip!' do
    expect(StringHelper.warnstrip!("#{warnstrip_string} ")).to eq(warnstrip_string)
  end
end
