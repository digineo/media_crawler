class Resource < ActiveRecord::Base
  
  # have to match:
  #   duration:"up to 1 hour"
  #   video_codec:h264
  #FIELD_PATTERN = /\w+:([^"\s]+|"[^"]+")/
  FIELD_PATTERN = /\w+:[\w\.-]+/
  
  belongs_to :server
  
  include Resource::Metadata
  include Resource::Search
  
  def uri
    "#{path}"
  end
  
end
