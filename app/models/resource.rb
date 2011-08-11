class Resource < ActiveRecord::Base
  
  FILE_PATTERN = /\.(avi|flv|mpe?g|mp[24]|mkv|wmv|)$/i
  
  FIELD_PATTERN = /\w+:[\w\.-]+/
  
  CHUNK_SIZE = 1024*50
  
  belongs_to :server
  
  include Resource::Metadata
  include Resource::Search
  
  def uri
    "#{path}"
  end
  
  def chunk_path
    "#{Rails.root}/data/servers/#{server_id}/chunks/#{id}"
  end
  
  def download_chunk(ftp)
    `mkdir -p '#{File.dirname(chunk_path)}'`
    
    conn = ftp.send :transfercmd, "RETR " << path
    begin
      data = conn.read(CHUNK_SIZE)
      # puts "#{data.length} bytes read"
      File.open(chunk_path, 'wb') do |f|
        f.write(data)
      end
    ensure
      conn.close
    end
  rescue Net::FTPTempError
    # no problem
  end
  
end
