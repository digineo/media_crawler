require 'net/http'

module Maintenance

  # scans the website for ftp-uris and adds them to the database
  def self.import_servers_from_uri(uri)
    uri  = URI.parse(uri) if uri.is_a?(String)
    page = Net::HTTP.get(uri)
    page.scan(%r(ftp://([\d.]+))).map(&:first).uniq.each do |address|
      Server.find_or_create_by(address: address )
    end
  end

end
