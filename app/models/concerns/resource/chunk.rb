module Resource::Chunk
  extend ActiveSupport::Concern
  
  included do
    after_destroy :delete_chunk
  end
  
  def chunk_path
    Rails.root.join "data/servers/#{server_id}/chunks/#{id}"
  end

  def chunk_exist?
    chunk_path.exist?
  end

  def download_chunk(ftp)
    chunk_path.dirname.mkpath
    retries = 0
    begin
      conn = ftp.send :transfercmd, "RETR " << path
      
      begin
        data = conn.read(Resource::CHUNK_SIZE)
        # puts "#{data.length} bytes read"
        File.open(chunk_path, 'wb') do |f|
          f.write(data)
        end
      ensure
        conn.close
      end
    rescue Net::FTPTempError
      sleep retries
      raise if retries > 1
      retries += 1
      retry
    end
  end
  
  def delete_chunk
    chunk_path.unlink if chunk_exist?
  end
  
end
