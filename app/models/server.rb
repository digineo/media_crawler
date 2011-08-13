require "net/ftp"
require "timeout"

class Server < ActiveRecord::Base
  
  has_many :resources
  
  def filelist_path
    "#{Rails.root}/data/servers/#{id}/filelist"
  end
  
  def update_files
    if download_filelist && parse_filelist
      self.files_updated_at = Time.now
      save!
    end
  end
  
  # does the filelist exists?
  def filelist?
    File.exists?(filelist_path) && filelist_size > 0
  end
  
  def filelist_size
    File.size(filelist_path)
  end
  
  def download_filelist
    `mkdir -p '#{File.dirname(filelist_path)}'`
    `lftp '#{host_ftp}' -e '
    set net:max-retries 3;
    set net:reconnect-interval-base 5;
    set net:reconnect-interval-max 15;
    set net:timeout 10;
    du -a;
    quit' > #{filelist_path}`
    $?.to_i == 0
  end
  
  def parse_filelist
    now         = Time.now
    files_count = 0
    
    f = File.open(filelist_path, "r") 
    f.each_line do |line|
      cols = line.strip.split("\t")
      size = cols[0]
      path = cols[1]
      path = path[1..-1] if path.to_s.starts_with?(".")
      
      # check file pattern
      next unless Resource::FILE_PATTERN =~ path
      
      # create/update resource
      resource = resources.find_or_initialize_by_path(path)
      resource.filesize = size.to_i * 1024
      resource.last_seen_at = now
      resource.save!
      
      files_count += 1
    end
    
    f.close
    
    # delete outdated resources
    resources.find_each(:conditions => ["last_seen_at IS null OR last_seen_at < ?", now]) do |r|
      r.destroy
    end
    
    files_count
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
  
  def update_state!
    `ping -c 1 -w 5 #{host_ftp}`
    self.state      = $?.to_i==0 ? 'up' : 'down'
    self.checked_at = Time.now
    save!
  end
  
  def up?
    state=='up'
  end
  
  def down?
    state=='down'
  end
  
  def host_ftp
    URI.parse(uri_ftp).host
  end
  
end
