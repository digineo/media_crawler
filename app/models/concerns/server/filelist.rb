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

    with_lock do
      `exec lftp #{host_ftp.shellescape} -e '
      set net:max-retries 3;
      set net:reconnect-interval-base 5;
      set net:reconnect-interval-max 15;
      set net:timeout 10;
      du -a;
      quit' > #{filelist_path.to_s.shellescape}`
    end
    
    # does not work properly
    #$?.to_i == 0
    
    # check if last line does contain the summarized size
    filelist_complete?
  end

  def filelist_complete?
    # last line should end with a size and a dot.
    !!`tail -n 1 #{filelist_path.to_s.shellescape}`.strip.match(/^\d+\t\.$/)
  end
  
  def parse_filelist
    files_count = 0
    ctime       = nil
    
    File.open(filelist_path, "rb") do |f|
      ctime = f.ctime

      f.each_line do |line|
        size, path = line.strip.split("\t",2)
        path = path[1..-1] if path.to_s.starts_with?(".")
        
        # check file pattern
        next unless Resource::FILE_PATTERN =~ path
        
        # create/update resource
        resource = resources.find_or_initialize_by(path: path)
        resource.filesize     = size.to_i * 1024
        resource.last_seen_at = ctime
        resource.save!
        
        files_count += 1
      end
    end
    
    # delete outdated resources
    resources.unseen_since(ctime).find_each(&:destroy)
    
    files_count
  end

end
