class Resource < ActiveRecord::Base
  
  FILE_PATTERN = /\.(avi|flv|mpe?g|mp[24]|mkv|wmv|)$/i
  FIELD_PATTERN = /\w+:[\w\.-]+/
  CHUNK_SIZE = 1024*50
  
  belongs_to :server
  
  include Resource::Metadata
  include Resource::Search
  
  scope :indexed, where(:indexed => true)
  scope :non_indexed, where(:indexed => false)
  
  def uri
    server.uri_ftp + path[1..-1]
  end
  
  def chunk_path
    "#{Rails.root}/data/servers/#{server_id}/chunks/#{id}"
  end
  
  def download_chunk(ftp)
    `mkdir -p '#{File.dirname(chunk_path)}'`
    retried = false
    begin
      conn    = ftp.send :transfercmd, "RETR " << path
      
      begin
        data = conn.read(CHUNK_SIZE)
        # puts "#{data.length} bytes read"
        File.open(chunk_path, 'wb') do |f|
          f.write(data)
        end
      ensure
        conn.close
      end
    rescue Net::FTPTempError => e
      raise e if retried
      retried = true
      retry
    end
  end
  
end
