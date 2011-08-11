require "net/ftp"

class Server < ActiveRecord::Base
  
  has_many :resources
  
  def update_files
    now  = Time.now
    dir  = "#{Rails.root}/data/servers/#{id}"
    file = "#{dir}/filelist"
    `mkdir -p '#{dir}'`
    `lftp '#{host_ftp}' -e '
    set net:max-retries 2;
    set net:reconnect-interval-base 5;
    set net:reconnect-interval-max 15;
    du -a' > #{file}`
    
    files_count = 0
    f = File.open(file, "r") 
    f.each_line do |line|
      cols = line.strip.split("\t")
      size = cols[0]
      path = cols[1]
      path = path[1..-1] if path.starts_with?(".")
      
      # check file pattern
      next unless Resource::FILE_PATTERN =~ path
      
      # create/update resource
      resource = resources.find_or_initialize_by_path(path)
      resource.filesize = size*1024
      resource.last_seen_at = now
      resource.save!
      
      files_count += 1
    end
    
    f.close
    
    files_count
  end
  
  def update_metadata
    ftp = Net::FTP.new(host_ftp)
    begin
      ftp.login
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
    
    self.checked_at = Time.now
    self.state = 'up'
    save!
  end
  
  def host_ftp
    URI.parse(uri_ftp).host
  end
  
end
