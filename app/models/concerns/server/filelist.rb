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
    tmpfile = filelist_path.to_s << ".new"

    with_lock do
      `exec lftp #{host_ftp.shellescape} -e '
      set net:max-retries 3;
      set net:reconnect-interval-base 5;
      set net:reconnect-interval-max 15;
      set net:timeout 10;
      du -a;
      quit' > #{tmpfile.shellescape}`
    end
    
    # does not work properly
    #$?.to_i == 0
    
    # check if last line contains the summarized size
    if size = Subprocess.run('tail', '-n', 1, tmpfile).strip.match(/^(\d+)\t\.$/)
      File.rename tmpfile, filelist_path
      update_attributes! total_size: size[1]
    end
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
        resource.filesize = size.to_i * 1024
        resource.seen_at  = ctime
        resource.save!
        
        files_count += 1
      end
    end
    
    # delete outdated resources
    resources.seen_before(ctime).each(&:destroy)
    
    files_count
  end

end
