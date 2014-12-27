require 'rails_helper'

describe PathSearch::Filter do

  context 'size' do
    let(:clazz){ PathSearch::Filter::Filesize }
    it{ expect(clazz.new("3k").to_h).to eq "gte" => 3 }
    it{ expect(clazz.new("1g").to_h).to eq "gte" => 1024*1024 }
    it{ expect(clazz.new(">1t").to_h).to eq "gt" => 1024*1024*1024 }
    it{ expect(clazz.new("5k..3.5m").to_h).to eq "gte" => 5, "lte" => (1024*3.5).round }
  end

end
