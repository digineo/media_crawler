require 'async_helper'

class Resource
  include Mongoid::Document

  field :path,      type: String
  field :filesize,  type: Integer
  field :seen_at,   type: DateTime
  field :checksum,  type: DateTime

  index({ server_id: 1, path: 1 }, { unique: true })

  FILE_PATTERN = /\.(avi|flv|mpe?g|mp[24]|mkv|wmv|)$/i
  FIELD_PATTERN = /\w+:[\w\.-]+/
  CHUNK_SIZE = 1024*50
  
  belongs_to :server
  
  require_dependency 'resource/metadata'
  include Resource::Metadata
  include Resource::Search
  include Resource::Chunk
  include Resource::Checksum
  include AsyncHelper
  
  scope :indexed,      ->{ where :checksum.exists => true }
  scope :non_indexed,  ->{ where :checksum => nil }
  scope :seen_before,  ->(time){ where :seent_at.lt => time }
  
  def uri
    server.address + path[1..-1]
  end
  
end
