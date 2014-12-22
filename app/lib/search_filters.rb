class SearchFilters
  
  attr_reader :invalid_fields, :remaining
  
  def initialize(query)
    @filters        = {}
    @invalid_fields = []
    
    @remaining = query.gsub(Resource::FIELD_PATTERN) do |expr|
      key, value = expr.split(":",2)
      key = key.to_sym
      
      case key
        when :audio_channels, :resolution, :server_id
          @filters[key] = value
        when :filesize
          min, max = value.include?("-") ? value.split("-") : value.split("..")
          @filters[key] = parse_filesize(min)..parse_filesize(max)
        when :duration
          min, max = value.include?("-") ? value.split("-") : value.split("..")
          @filters[key] = parse_duration(min)..parse_duration(max)
        when :duration_min, :duration_max
          @filters[key] = parse_duration(value)
        when :video_codec, :audio_codec, :audio_languages, :subtitle_languages
          @filters[key] ||= []
          @filters[key] += value.include?(",") ? value.split(",") : [value.to_s]
        else
          @invalid_fields << key
      end
      
      nil
    end
  end
  
  def [](key)
    @filters[key]
  end
  
  def parse_duration(value)
    if value.include?(":")
      h, m = value.split(":")
      h.to_i * 60 + m.to_i
    else
      value.to_i
    end
  end
  
  def parse_filesize(value)
    case value
      when /^\d+k$/i
        value.to_i.kilobytes
      when /^\d+m$/i
        value.to_i.megabytes
      when /^\d+g$/i
        value.to_i.gigabytes
      else
        value.to_i
    end
  end

end
