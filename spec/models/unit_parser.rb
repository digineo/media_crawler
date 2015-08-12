require 'rails_helper'

describe UnitParser do

  describe 'search with query' do
    it { expect(UnitParser.to_str(123)).to eq 123 }
    it { expect(UnitParser.to_str(1024)).to eq "1k" }
    it { expect(UnitParser.to_str(1025)).to eq 1025 }
    it { expect(UnitParser.to_int("3gb")).to eq 3*1024**3 }
    it { expect(UnitParser.to_int("1tb")).to eq 1024**4 }
  end

end
