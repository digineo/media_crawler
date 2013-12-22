module Resource::Search
  extend ActiveSupport::Concern
  
  included do
    searchable :auto_index => false do
      text :path_without_filename, :as => 'path_without_filename_tpath'
      text :filename, :as => 'filename_tpath'
      integer :server_id
      integer :duration
      string :audio_codecs, :multiple => true
      string :audio_channels, :multiple => true
      string :audio_languages, :multiple => true
      string :subtitle_languages, :multiple => true
      string :video_codec
      string :resolution
      string :checksum
      integer :filesize, :as => 'filesize_l'
      integer :height
      integer :width
    end
  end
  
  def filename
    path.split("/").last
  end
  
  def path_without_filename
    path.sub(%r(/[^/]+$),"")
  end
  
end
