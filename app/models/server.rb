require "net/ftp"
require "timeout"

class Server
  include Mongoid::Document

  field :name,      type: String
  field :addresses, type: String
  field :state,     type: String
  
  field :files_updated_at,   type: DateTime
  field :chunks_upadated_at, type: DateTime

  field :total_size

  require_dependency 'server/metadata'
  include Server::Filelist
  include Server::Locking
  include Server::Metadata
  include Server::State

  has_many :resources
  
  def data_path
    Rails.root.join("data/servers/#{id}")
  end

  def update_all
    update_state!
    if up?
      update_files && update_metadata
    end
  end

  def address
    "ftp://#{host_ftp}"
  end
  
  def host_ftp
    addresses.split.first
  end

end
