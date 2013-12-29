module Resource::Chunk
  extend ActiveSupport::Concern
  
  included do
    after_destroy :delete_chunk
  end
  
  def chunk_path
    data_path.join("chunks/#{id}")
  end
  
  def download_chunk(ftp)
    chunk_path.dirname.mkpath
    retried = false
    begin
      conn    = ftp.send :transfercmd, "RETR " << path
      
      begin
        data = conn.read(Resource::CHUNK_SIZE)
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
  
  def delete_chunk
    File.unlink(chunk_path) if File.exists?(chunk_path)
  end
  
end
