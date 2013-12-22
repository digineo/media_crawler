module Server::Filelist
  extend ActiveSupport::Concern

  def filelist_path
    data_path.join("filelist")
  end

  # does the filelist exists?
  def filelist?
    filelist_path.exist? && filelist_size > 0
  end
  
  def filelist_size
    filelist_path.size
  end

  def update_files
    if download_filelist && parse_filelist
      self.files_updated_at = Time.now
      save!
      true
    end
  end

  def download_filelist
    # ensure directory exists
    filelist_path.dirname.mkpath

    `lftp '#{host_ftp}' -e '
    set net:max-retries 3;
    set net:reconnect-interval-base 5;
    set net:reconnect-interval-max 15;
    set net:timeout 10;
    du -a;
    quit' > #{filelist_path}`
    
    # does not work properly
    #$?.to_i == 0
    
    # check if last line does contain the summarized size
    line = `tail -n 1 #{filelist_path}`.strip
    line =~ /^\d+\t\.$/
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

end
