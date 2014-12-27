module Server::Metadata
  extend ActiveSupport::Concern

  def update_metadata
    with_lock :ftp do
      update_metadata_without_lock
    end
  end

  private

  def update_metadata_without_lock
    ftp = nil
    
    # connect
    Timeout::timeout(15) {
      ftp = Net::FTP.new(host_ftp)
    }
    begin
      # login
      ftp.login
      
      # index non-indexed resources
      #resources.non_indexed.each do |resource|
      resources.each do |resource|
        begin
          resource.download_chunk(ftp)
          puts "#{resource.id} '#{resource.path}' downloaded"
          resource.async :update_metadata
        rescue Net::FTPPermError => e
          puts "#{resource.id} '#{resource.path}': #{e.message}"
        end
      end
    ensure
      ftp.close
    end
    
    self.chunks_upadated_at = Time.now
    save!
  end

end
