require 'rails_helper'

describe UnitParser do

  describe 'search with query' do
    it { expect(UnitParser.filesize_to_str(123)).to eq 123 }
    it { expect(UnitParser.filesize_to_str(1024)).to eq "1k" }
    it { expect(UnitParser.filesize_to_str(1025)).to eq 1025 }
  end

end
