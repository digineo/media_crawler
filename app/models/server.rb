require "net/ftp"
require "timeout"

class Server < ActiveRecord::Base
  
  include Server::Filelist
  include Server::State

  has_many :resources
  
  def data_path
    Rails.root.join("data/servers/#{id}")
  end
  
  def update_all
    update_state!
    if up?
      update_files && update_metadata
    end
  end
  
  def update_metadata
    ftp = nil
    
    # connect
    Timeout::timeout(15) {
      ftp = Net::FTP.new(host_ftp)
    }
    begin
      # login
      ftp.login
      
      # index non-indexed resources
      resources.non_indexed.find_each do |resource|
        begin
          resource.download_chunk(ftp)
          resource.update_metadata
        rescue Net::FTPPermError => e
          puts "#{resource.id} #{resource.path}: #{e.message}"
        end
      end
    ensure
      ftp.close
    end
    
    self.metadata_updated_at = Time.now
    save!
  end
  
  def host_ftp
    URI.parse(uri_ftp).host
  end
  
end
