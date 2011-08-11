class Server < ActiveRecord::Base
  
  has_many :resources
  
  def update_files
    now  = Time.now
    dir  = "#{Rails.root}/data/servers/#{id}"
    file = "#{dir}/filelist"
    `mkdir -p '#{dir}'`
    `lftp '#{host_ftp}' -e "du -a" > #{file}`
    
    f = File.open(file, "r") 
    f.each_line do |line|
      cols = line.strip.split("\t")
      size = cols[0]
      path = cols[1]
      path = path[1..-1] if path.starts_with?(".")
      
      next unless Resource::FILE_PATTERN =~ path
      
      resource = resources.find_or_initialize_by_path(path)
      resource.filesize = size
      resource.last_seen_at = now
      resource.save!
    end
    
    f.close
  end
  
  def host_ftp
    URI.parse(uri_ftp).host
  end
  
end
