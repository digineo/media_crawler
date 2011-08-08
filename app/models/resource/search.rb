module Resource::Search
  extend ActiveSupport::Concern
  
  included do
    searchable do
      text :path, :stored => true do
        normalized_path
      end
      integer :server_id
      integer :duration
      string :audio_codecs, :multiple => true
      string :audio_channels, :multiple => true
      string :audio_languages, :multiple => true
      string :subtitle_languages, :multiple => true
      string :video_codec
      string :resolution
      integer :height
      integer :width
    end
  end
  
  module InstanceMethods
    def normalized_path
      path.gsub("/"," / ").gsub("."," . ").gsub("-"," - ")
    end
  end
  
end