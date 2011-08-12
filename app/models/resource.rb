class Resource < ActiveRecord::Base
  
  FILE_PATTERN = /\.(avi|flv|mpe?g|mp[24]|mkv|wmv|)$/i
  FIELD_PATTERN = /\w+:[\w\.-]+/
  CHUNK_SIZE = 1024*50
  
  belongs_to :server
  
  include Resource::Metadata
  include Resource::Search
  include Resource::Chunk
  include Resource::Checksum
  
  scope :indexed, where(:indexed => true)
  scope :non_indexed, where(:indexed => false)
  
  def uri
    server.uri_ftp + path[1..-1]
  end
  
end
