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
    field :duration,           type: Integer
    field :audio_streams,      type: Array
    field :video_streams,      type: Array
    field :subtitle_languages, type: Array
  end

  def metadata
    @metadata ||= FFMPEG::Movie.new(chunk_path.to_s)
  end

  def update_metadata
    if metadata.valid?
      self.duration      = (metadata.duration / 60).ceil # to minutes
      self.audio_streams = metadata.audio_streams.map{|s|{
        codec:      s.codec,
        language:   s.language,
        channels:   s.channels
      }}
      self.video_streams = metadata.video_streams.map{|s|{
        codec:      s.codec.try(:split).try(:first),
        width:      s.width,
        height:     s.height,
        resolution: self.class.resolution(s.width, s.height)
      }}
      self.subtitle_languages = metadata.subtitles.map(&:language).compact.uniq
    else
      self.duration           = nil
      self.audio_streams      = nil
      self.video_streams      = nil
      self.subtitle_languages = nil
    end

    update_checksum
    save! unless new_record?
    __elasticsearch__.index_document
  end

  # Delegation to the first video stream
  %i( video_codec resolution height width ).each do |method|
    define_method method do
      video_streams.first.try :[], method if video_streams.present?
    end
  end

  def audio_languages
    (audio_streams || []).map{|s| s[:language] }.compact.uniq
  end
  
  def audio_channels
    (audio_streams || []).map{|s| s[:channels] }.compact.uniq
  end
  
  def width_height
    "#{width}x#{height}"
  end
  
  module ClassMethods
    def resolution(width, height)
      return "unknown" if !width || !height
      for res in RESOLUTIONS
        return res[0] if width >= res[1]*0.95 || height >= res[2]*0.95
      end
      "unknown"
    end
  end
  
end
