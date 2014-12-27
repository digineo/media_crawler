require 'rails_helper'

describe Server::Filelist do

  describe 'importing filelist' do
    let(:server){ create :server }

    before do
      expect(server).to receive(:filelist_path){ Rails.root.join("spec/fixtures/filelist") }
    end

    context 'updating cache' do
      it { server.generate_cache }
    end

    context 'updating paths', :elasticsearch do
      before do
        server.update_paths
        Path.refresh_index!
      end

      it { expect(Path.count).to eq 9 }
    end
  end

end
