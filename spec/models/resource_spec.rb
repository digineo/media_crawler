require 'rails_helper'

describe Resource do

  describe "resolution" do
    it { expect(Resource.resolution(1920, 816)).to eq '1080p' }
    it { expect(Resource.resolution(1280, 720)).to eq '720p' }
  end

end
