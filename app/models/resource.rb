class Resource < ActiveRecord::Base
  
  FILE_PATTERN = /\.(avi|flv|mpe?g|mp[24]|mkv|wmv|)$/i
  
  FIELD_PATTERN = /\w+:[\w\.-]+/
  
  belongs_to :server
  
  include Resource::Metadata
  include Resource::Search
  
  def uri
    "#{path}"
  end
  
end
