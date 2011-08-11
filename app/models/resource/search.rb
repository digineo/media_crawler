module Resource::Search
  extend ActiveSupport::Concern
  
  included do
    searchable :auto_index => false do
      text :path, :as => 'path_tpath'
      integer :server_id
      integer :duration
      string :audio_codecs, :multiple => true
      string :audio_channels, :multiple => true
      string :audio_languages, :multiple => true
      string :subtitle_languages, :multiple => true
      string :video_codec
      string :resolution
      integer :filesize, :as => 'filesize_l'
      integer :height
      integer :width
    end
  end
  
end