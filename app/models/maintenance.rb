require 'net/http'

module Maintenance
  
  def self.update_all
    Server.order("files_updated_at").find_each(&:update_all)
  end
  
  def self.update_files
    Server.order("files_updated_at").find_each(&:update_files)
  end
  
  def self.update_metadata
    Server.order("metadata_updated_at").find_each(&:update_metadata)
  end
  
  # scans the website for ftp-uris and adds them to the database
  def self.import_servers_from_uri(uri)
    uri  = URI.parse(uri) if uri.is_a?(String)
    page = Net::HTTP.get(uri)
    page.scan(%r(ftp://([\d.]+))).map(&:first).uniq.each do |address|
      Server.find_or_create_by(addresses: address )
    end
  end
  
end
