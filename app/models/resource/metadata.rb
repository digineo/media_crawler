module Resource::Metadata
  extend ActiveSupport::Concern
  
  RESOLUTIONS = [
    ["4320p", 7680, 4320],
    ["1080p", 1080, 1920],
    ["720p",   720, 1280],
    ["480p",   480,  640],
    ["360p",   360,  240],
    ["240p",   240,  160]
  ]
  
  included do
    scope :non_indexed, where(:indexed => false)
    
    serialize :metadata
  end
  
  module InstanceMethods
    
    def update_filesize
      self.filesize = File.stat(path).size
    end
    
    def update_metadata
      self.metadata = FFMPEG::Movie.new(path)
      self.indexed  = true
      self.save! unless new_record?
      solr_index!
    end
    
    def audio_streams
      metadata.audio_streams
    end
    
    def video_streams
      metadata.video_streams
    end
    
    def audio_codecs
      audio_streams.map(&:codec).compact.uniq
    end
    
    def video_codec
      video_streams.first.codec if video_streams.any?
    end
    
    def audio_languages
      audio_streams.map(&:language).compact.uniq
    end
    
    def subtitle_languages
      metadata.subtitles.map(&:language).compact.uniq
    end
    
    def audio_channels
      audio_streams.map(&:channels).compact.uniq
    end
    
    def duration
      (metadata.duration / 60).ceil
    end
    
    def height
      metadata.height
    end
    
    def width
      metadata.width
    end
    
    def width_height
      "#{width}x#{height}"
    end
    
    def resolution
      return "unknown" if !width || !height
      for res in RESOLUTIONS
        return res[0] if width >= res[1]*0.95 || height >= res[2]*0.95
      end
      "unknown"
    end
  end
  
end