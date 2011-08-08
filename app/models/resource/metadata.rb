module Resource::Metadata
  extend ActiveSupport::Concern
  
  included do
    before_create :update_size
    before_create :update_metadata
    
    serialize :metadata
  end
  
  module InstanceMethods
    
    def update_size
      self.size = File.stat(path).size
    end
    
    def update_metadata
      self.metadata = FFMPEG::Movie.new(path)
      self.save! unless new_record?
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
    
    def resolution
      "#{height}x#{width}"
    end
  end
  
end