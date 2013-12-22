require 'digest/sha1'

module Resource::Checksum
  extend ActiveSupport::Concern
  
  def update_checksum
    self.checksum = Digest::SHA1.hexdigest(File.read(chunk_path) << "-" << filesize.to_s)
  end
  
  def update_checksum!
    update_checksum
    save!
  end
  
end
