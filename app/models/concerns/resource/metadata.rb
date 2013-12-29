module Resource::Metadata
  extend ActiveSupport::Concern
  
  RESOLUTIONS = [
    ["4320p", 7680, 4320],
    ["1080p", 1920, 1080],
    ["720p",  1280,  720],
    ["480p",   640,  480],
    ["360p",   360,  240],
    ["240p",   240,  160]
  ]
  
  included do
    serialize :metadata
  end
    
  def update_metadata
    self.metadata = FFMPEG::Movie.new(chunk_path.to_s)
    self.indexed  = true
    self.update_checksum
    self.save! unless new_record?
    self.update_index
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
    video_streams.first.codec.try(:split).try(:first) if video_streams.any?
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
